// Copyright (c) 2026 Zaid Rahhawi
// SPDX-License-Identifier: MIT
// See LICENSE for license information.

import ArgumentParser
import AuthCore
import AuthGRPC
import AuthLog
import AuthPostgres
import Configuration
import GRPCCore
import GRPCNIOTransportHTTP2
import GRPCOTelTracingInterceptors
import GRPCServiceLifecycle
import HarborAuthentication
import HarborPersistence
import HarborTransport
import Logging
import NIOCertificateReloading
import OTel
import PersistencePostgres
import PostgresNIO
import ServiceLifecycle
import Temporal
import UnixSignals

struct Run: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "run",
        abstract: "Run the registration workflows' worker"
    )

    func run() async throws {
        // MARK: - Configuration
        let config = ConfigReader(providers: [
            EnvironmentVariablesProvider(),
            InMemoryProvider.applicationDefaults,
        ])

        // MARK: - Logging
        let logLevel = config.string(forKey: "logLevel", as: Logger.Level.self, default: .info)
        let traceMetadataProvider = OTel.makeLoggingMetadataProvider()
        let metadataProvider = Logger.MetadataProvider.multiplex([.user, traceMetadataProvider])
        LoggingSystem.bootstrap(
            { label, metadataProvider in
                var handler = StreamLogHandler.standardOutput(label: label, metadataProvider: metadataProvider)
                handler.logLevel = logLevel
                return handler
            },
            metadataProvider: metadataProvider
        )
        let logger = Logger(label: "harbor-auth-worker")

        // MARK: - Observability
        var otelConfiguration = OTel.Configuration.default
        otelConfiguration.serviceName = "harbor-auth-worker"
        otelConfiguration.logs.enabled = false
        let observability = try OTel.bootstrap(configuration: otelConfiguration)

        // MARK: - Infrastructure
        let tlsConfig = config.scoped(to: "tls")
        var certificateReloaderConfiguration = try TimedCertificateReloader.Configuration(config: tlsConfig)
        certificateReloaderConfiguration.logger = logger
        certificateReloaderConfiguration.onCertificateLoadFailed = { failure in
            logger.warning(
                "Certificate reload failed: keeping the last good pair",
                metadata: ["error": "\(failure.error)"]
            )
        }
        let certificateReloader = try TimedCertificateReloader.makeReloaderValidatingSources(
            configuration: certificateReloaderConfiguration
        )
        let clientSecurity: HTTP2ClientTransport.Posix.TransportSecurity = try .mTLS(
            config: tlsConfig,
            certificateReloader: certificateReloader
        )

        let postgresConfig = config.scoped(to: "postgres")
        let workerPostgresConfiguration = try PostgresClient.Configuration(config: postgresConfig, role: "service")
        let workerPostgresClient = PostgresClient(configuration: workerPostgresConfiguration, backgroundLogger: logger)

        let usersConfig = config.scoped(to: "grpc.users")
        let usersHost = try usersConfig.requiredString(forKey: "host")
        let usersPort = try usersConfig.requiredInt(forKey: "port")
        let usersTransportConfig = HTTP2ClientTransport.Posix.Config(config: usersConfig)
        let usersServiceConfig = ServiceConfig(config: usersConfig)
        let usersTransport = try HTTP2ClientTransport.Posix(
            target: .dns(host: usersHost, port: usersPort),
            transportSecurity: clientSecurity,
            config: usersTransportConfig,
            serviceConfig: usersServiceConfig
        )
        let usersTracing = ClientOTelTracingInterceptor(serverHostname: usersHost, networkTransportMethod: "tcp")
        let usersGRPCClient = GRPCClient(
            transport: usersTransport,
            interceptorPipeline: [.apply(usersTracing, to: .all)]
        )

        let temporalConfig = config.scoped(to: "temporal")
        let temporalHost = try temporalConfig.requiredString(forKey: "host")
        let temporalPort = try temporalConfig.requiredInt(forKey: "port")
        let temporalTLSConfig = temporalConfig.scoped(to: "tls")
        var temporalCertificateReloaderConfiguration = try TimedCertificateReloader.Configuration(
            config: temporalTLSConfig
        )
        temporalCertificateReloaderConfiguration.logger = logger
        temporalCertificateReloaderConfiguration.onCertificateLoadFailed = { failure in
            logger.warning(
                "Temporal certificate reload failed: keeping the last good pair",
                metadata: ["error": "\(failure.error)"]
            )
        }
        let temporalCertificateReloader = try TimedCertificateReloader.makeReloaderValidatingSources(
            configuration: temporalCertificateReloaderConfiguration
        )
        let temporalSecurity: HTTP2ClientTransport.Posix.TransportSecurity = try .mTLS(
            config: temporalTLSConfig,
            certificateReloader: temporalCertificateReloader
        )

        // MARK: - Composition
        // System use cases act for no caller; Auth has no tenant table, so the worker runs as auth_service.
        let workerDatabase = PostgresDatabase<PostgresAuthScope>(client: workerPostgresClient, logger: logger)
        let registrationConfig = config.scoped(to: "registration")
        let registrationPolicy = try RegistrationPolicy(config: registrationConfig)
        let emailConfig = config.scoped(to: "email")
        let verificationEmailSender = try LogVerificationEmailSender(config: emailConfig, logger: logger)
        let usersClient = GRPCUsersClient(client: usersGRPCClient)

        let sendVerificationEmailUseCase = SendVerificationEmailUseCase(
            database: workerDatabase,
            verificationEmailSender: verificationEmailSender,
            policy: registrationPolicy,
            logger: logger
        )
        let expireRegistrationUseCase = ExpireRegistrationUseCase(database: workerDatabase, logger: logger)
        let completeRegistrationUseCase = CompleteRegistrationUseCase(
            database: workerDatabase,
            usersClient: usersClient,
            logger: logger
        )
        let registrationActivities = RegistrationActivities(
            sendVerificationEmailUseCase: sendVerificationEmailUseCase,
            expireRegistrationUseCase: expireRegistrationUseCase,
            completeRegistrationUseCase: completeRegistrationUseCase
        )

        // MARK: - Worker
        var workerConfiguration = try TemporalWorker.Configuration(configReader: temporalConfig)
        // Lets in-flight activities finish on a deploy, rather than cancelling and repeating them.
        workerConfiguration.gracefulShutdownPeriod = try temporalConfig.requiredInt(
            forKey: "worker.gracefulShutdownPeriodSeconds",
            as: Duration.self
        )
        let worker = try TemporalWorker(
            configuration: workerConfiguration,
            target: .dns(host: temporalHost, port: temporalPort),
            transportSecurity: temporalSecurity,
            activityContainers: registrationActivities,
            workflows: [RegistrationWorkflow.self]
        )

        // MARK: - Lifecycle
        let serviceGroup = ServiceGroup(
            services: [
                observability,
                certificateReloader,
                temporalCertificateReloader,
                workerPostgresClient,
                usersGRPCClient,
                worker,
            ],
            gracefulShutdownSignals: [.sigterm, .sigint],
            logger: logger
        )
        logger.info("Worker running", metadata: ["taskQueue": "\(workerConfiguration.taskQueue)"])
        try await withLogger(logger) { _ in
            try await serviceGroup.run()
        }
    }
}
