import AsyncAlgorithms
import AuthCore
import Logging
import PostgresNIO

#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

struct PostgresAccountRepository: AccountRepository {
    let connection: PostgresConnection
    let logger: Logger

    func create(_ command: CreateAccountCommand) async throws -> Account {
        do {
            let statement = CreateAccountStatement(command: command)
            let rows = try await connection.execute(statement, logger: logger)
            let accounts = try await Array(rows)
            // The key's account holds another address, so the conflict's update matched no row.
            guard let account = accounts.first else {
                throw AccountRepositoryError.idempotencyConflict
            }

            return account
        } catch let error as PSQLError where error.serverInfo?[.sqlState] == "23505" {
            switch error.serverInfo?[.constraintName] {
            case "accounts_email_key":
                throw AccountRepositoryError.duplicateEmail
            default:
                throw error
            }
        }
    }

    func account(id: UUID) async throws -> Account? {
        let statement = AccountByIDStatement(id: id)
        let rows = try await connection.execute(statement, logger: logger)
        let accounts = try await Array(rows)
        return accounts.first
    }

    func account(email: EmailAddress) async throws -> Account? {
        let statement = AccountByEmailStatement(email: email.rawValue)
        let rows = try await connection.execute(statement, logger: logger)
        let accounts = try await Array(rows)
        return accounts.first
    }

    func markVerified(id: UUID) async throws -> Account? {
        let statement = MarkAccountVerifiedStatement(id: id)
        let rows = try await connection.execute(statement, logger: logger)
        let accounts = try await Array(rows)
        return accounts.first
    }

    func deletePending(id: UUID) async throws -> Account? {
        let statement = DeletePendingAccountStatement(id: id)
        let rows = try await connection.execute(statement, logger: logger)
        let accounts = try await Array(rows)
        return accounts.first
    }
}
