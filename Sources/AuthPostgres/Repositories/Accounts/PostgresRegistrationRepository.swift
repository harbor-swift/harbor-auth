import AsyncAlgorithms
import AuthCore
import Logging
import PostgresNIO

#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

struct PostgresRegistrationRepository: RegistrationRepository {
    let connection: PostgresConnection
    let logger: Logger

    func create(_ command: CreateRegistrationCommand) async throws -> Registration {
        let statement = CreateRegistrationStatement(command: command)
        let rows = try await connection.execute(statement, logger: logger)
        let registrations = try await Array(rows)
        // The account's registration holds another name, so the conflict's update matched no row.
        guard let registration = registrations.first else {
            throw RegistrationRepositoryError.idempotencyConflict
        }

        return registration
    }

    func registration(accountID: UUID) async throws -> Registration? {
        let statement = RegistrationByAccountIDStatement(accountID: accountID)
        let rows = try await connection.execute(statement, logger: logger)
        let registrations = try await Array(rows)
        return registrations.first
    }

    func registration(verificationTokenDigest: String) async throws -> Registration? {
        let statement = RegistrationByVerificationTokenDigestStatement(digest: verificationTokenDigest)
        let rows = try await connection.execute(statement, logger: logger)
        let registrations = try await Array(rows)
        return registrations.first
    }

    func storeVerificationToken(_ command: StoreVerificationTokenCommand) async throws -> Registration? {
        let statement = StoreVerificationTokenStatement(command: command)
        let rows = try await connection.execute(statement, logger: logger)
        let registrations = try await Array(rows)
        return registrations.first
    }

    func delete(accountID: UUID) async throws -> Registration? {
        let statement = DeleteRegistrationStatement(accountID: accountID)
        let rows = try await connection.execute(statement, logger: logger)
        let registrations = try await Array(rows)
        return registrations.first
    }
}
