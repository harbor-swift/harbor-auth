// Copyright (c) 2026 Zaid Rahhawi
// SPDX-License-Identifier: MIT
// See LICENSE for license information.

import ArgumentParser
import AuthBcrypt
import AuthCore
import AuthGRPC
import AuthPostgres
import AuthProtos
import AuthenticationJWT
import Configuration
import GRPCCore
import GRPCHealthService
import GRPCNIOTransportHTTP2
import GRPCOTelTracingInterceptors
import GRPCServiceLifecycle
import HarborAuthentication
import HarborPersistence
import HarborTransport
import JWTKit
import Logging
import NIOCertificateReloading
import OTel
import PersistencePostgres
import PostgresNIO
import ServiceLifecycle
import Temporal
import UnixSignals

struct Serve: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "serve",
        abstract: "Serve the auth gRPC services"
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
        let logger = Logger(label: "harbor-auth")

        // MARK: - Observability
        var otelConfiguration = OTel.Configuration.default
        otelConfiguration.serviceName = "harbor-auth"
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

        let postgresConfig = config.scoped(to: "postgres")
        let servicePostgresConfiguration = try PostgresClient.Configuration(config: postgresConfig, role: "service")
        let postgresClient = PostgresClient(configuration: servicePostgresConfiguration, backgroundLogger: logger)

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
        let temporalClientConfiguration = try TemporalClient.Configuration(configReader: temporalConfig)
        let temporalClient = try TemporalClient(
            target: .dns(host: temporalHost, port: temporalPort),
            transportSecurity: temporalSecurity,
            configuration: temporalClientConfiguration
        )

        let jwtConfig = config.scoped(to: "jwt")
        let privateKey = try EdDSA.PrivateKey(config: jwtConfig)
        let credentialIssuer = await JWTIssuer<UserIdentity>(privateKey: privateKey)

        // MARK: - Composition
        // Every RPC here is anyone's and Auth has no tenant table, so every use case runs as auth_service.
        let database = PostgresDatabase<PostgresAuthScope>(client: postgresClient, logger: logger)
        let taskQueue = try temporalConfig.requiredString(forKey: "worker.taskqueue")
        let passwordsConfig = config.scoped(to: "passwords")
        let passwordPolicy = try PasswordPolicy(config: passwordsConfig)
        let sessionsConfig = config.scoped(to: "sessions")
        let sessionPolicy = try SessionPolicy(config: sessionsConfig)
        let passwordHasher = BcryptPasswordHasher(cost: passwordPolicy.bcryptCost)

        let registerUseCase = RegisterUseCase(
            database: database,
            passwordHasher: passwordHasher,
            temporalClient: temporalClient,
            taskQueue: taskQueue,
            policy: passwordPolicy,
            logger: logger
        )
        let verifyEmailUseCase = VerifyEmailUseCase(
            database: database,
            temporalClient: temporalClient,
            taskQueue: taskQueue,
            logger: logger
        )
        let signInUseCase = SignInUseCase(
            database: database,
            passwordHasher: passwordHasher,
            credentialIssuer: credentialIssuer,
            policy: sessionPolicy,
            logger: logger
        )
        let refreshSessionUseCase = RefreshSessionUseCase(
            database: database,
            credentialIssuer: credentialIssuer,
            policy: sessionPolicy,
            logger: logger
        )
        let authService = AuthService(
            registerUseCase: registerUseCase,
            verifyEmailUseCase: verifyEmailUseCase,
            signInUseCase: signInUseCase,
            refreshSessionUseCase: refreshSessionUseCase
        )

        // MARK: - gRPC
        let serverConfig = config.scoped(to: "grpc.server")
        let serverHost = try serverConfig.requiredString(forKey: "host")
        let serverPort = try serverConfig.requiredInt(forKey: "port")
        let serverHostname = try serverConfig.requiredString(forKey: "hostname")
        let serverSecurity: HTTP2ServerTransport.Posix.TransportSecurity = try .mTLS(
            config: tlsConfig,
            certificateReloader: certificateReloader
        )
        let serverTransportConfig = HTTP2ServerTransport.Posix.Config(config: serverConfig)
        let serverTransport = HTTP2ServerTransport.Posix(
            address: .ipv4(host: serverHost, port: serverPort),
            transportSecurity: serverSecurity,
            config: serverTransportConfig
        )
        // Auth serves no internal RPC, so no RPC lists callers and the interceptor passes every call.
        let callers: [MethodDescriptor: Set<String>] = [:]
        let internalCallers = InternalCallerInterceptor(callers: callers, logger: logger)
        let serverTracing = ServerOTelTracingInterceptor(serverHostname: serverHostname, networkTransportMethod: "tcp")
        let healthService = HealthService()
        healthService.provider.updateStatus(.serving, forService: "")
        let server = GRPCServer(
            transport: serverTransport,
            services: [authService, healthService],
            interceptorPipeline: [
                .apply(internalCallers, to: .all),
                .apply(serverTracing, to: .services([Harbor_Auth_V1_AuthService.descriptor])),
            ]
        )

        // MARK: - Lifecycle
        let serviceGroup = ServiceGroup(
            services: [
                observability,
                certificateReloader,
                temporalCertificateReloader,
                postgresClient,
                temporalClient,
                server,
            ],
            gracefulShutdownSignals: [.sigterm, .sigint],
            logger: logger
        )
        logger.info("Serving", metadata: ["port": "\(serverPort)"])
        try await withLogger(logger) { _ in
            try await serviceGroup.run()
        }
    }
}
