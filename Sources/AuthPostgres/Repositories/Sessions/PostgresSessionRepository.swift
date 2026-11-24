import AsyncAlgorithms
import AuthCore
import Logging
import PostgresNIO

#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

struct PostgresSessionRepository: SessionRepository {
    let connection: PostgresConnection
    let logger: Logger

    func create(_ command: CreateSessionCommand) async throws -> Session {
        let statement = CreateSessionStatement(command: command)
        let rows = try await connection.execute(statement, logger: logger)
        let sessions = try await Array(rows)
        // The insert reads the account's status, and an account that isn't active returns no row.
        guard let session = sessions.first else {
            throw SessionRepositoryError.accountInactive
        }

        return session
    }

    func useRefreshToken(digest: String) async throws -> RefreshToken? {
        let statement = UseRefreshTokenStatement(digest: digest)
        let rows = try await connection.execute(statement, logger: logger)
        let refreshTokens = try await Array(rows)
        return refreshTokens.first
    }

    func refreshToken(digest: String) async throws -> RefreshToken? {
        let statement = RefreshTokenByDigestStatement(digest: digest)
        let rows = try await connection.execute(statement, logger: logger)
        let refreshTokens = try await Array(rows)
        return refreshTokens.first
    }

    func addRefreshToken(_ command: AddRefreshTokenCommand) async throws -> RefreshToken {
        let statement = CreateRefreshTokenStatement(sessionID: command.sessionID, digest: command.digest)
        let rows = try await connection.execute(statement, logger: logger)
        let refreshTokens = try await Array(rows)
        // The insert reads the session's end, and an ended session returns no row.
        guard let refreshToken = refreshTokens.first else {
            throw SessionRepositoryError.sessionEnded
        }

        return refreshToken
    }

    func end(sessionID: UUID) async throws -> Session? {
        let statement = EndSessionStatement(sessionID: sessionID)
        let rows = try await connection.execute(statement, logger: logger)
        let sessions = try await Array(rows)
        return sessions.first
    }
}
