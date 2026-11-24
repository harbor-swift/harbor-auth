package import Authentication
package import HarborAuthentication
package import Logging
package import Persistence

#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

/// Trades a refresh token for a new access token and the refresh token that replaces it.
///
/// Each refresh token works once. A used one presented again was copied, by whoever holds either copy, so its
/// whole session ends and the holder of the real one signs in again. Runs on `auth_service`.
package struct RefreshSessionUseCase<DatabaseType>: RefreshSessionUseCaseProtocol
where DatabaseType: Database, DatabaseType.Scope: RefreshSessionUseCaseScope {
    private let database: DatabaseType
    private let credentialIssuer: any CredentialIssuer<UserIdentity, String>
    private let policy: SessionPolicy
    private let logger: Logger

    package init(
        database: DatabaseType,
        credentialIssuer: any CredentialIssuer<UserIdentity, String>,
        policy: SessionPolicy,
        logger: Logger
    ) {
        self.database = database
        self.credentialIssuer = credentialIssuer
        self.policy = policy
        self.logger = logger
    }

    package func callAsFunction(
        input: RefreshSessionUseCaseInput
    ) async throws(RefreshSessionUseCaseError) -> SessionTokens {
        guard !input.refreshToken.isEmpty else {
            throw .refreshTokenRejected
        }

        let presentedDigest = OpaqueToken.digest(of: input.refreshToken)
        let successor = OpaqueToken.generate()

        do {
            let usedToken = try await database.withTransaction { scope -> RefreshToken? in
                guard let usedToken = try await scope.sessionRepository.useRefreshToken(digest: presentedDigest) else {
                    return nil
                }

                let command = AddRefreshTokenCommand(sessionID: usedToken.sessionID, digest: successor.digest)
                _ = try await scope.sessionRepository.addRefreshToken(command)
                return usedToken
            }

            guard let usedToken else {
                // Ended in a transaction of its own, so the refusal doesn't roll the end back.
                let endedSession = try await database.withTransaction { scope -> Session? in
                    let presentedToken = try await scope.sessionRepository.refreshToken(digest: presentedDigest)
                    guard let presentedToken, presentedToken.status == .used else {
                        return nil
                    }

                    return try await scope.sessionRepository.end(sessionID: presentedToken.sessionID)
                }
                if let endedSession {
                    logger.warning(
                        "Refresh refused: a used refresh token was presented again, so its session ended",
                        metadata: ["sessionID": "\(endedSession.id)"]
                    )
                } else {
                    logger.warning("Refresh refused: unknown refresh token or ended session")
                }
                throw RefreshSessionUseCaseError.refreshTokenRejected
            }

            let issueDate = Date.now
            let identity = policy.identity(userID: usedToken.accountID, issuedAt: issueDate)
            let accessToken = try await credentialIssuer.issue(for: identity)
            logger.info("Session refreshed", metadata: ["sessionID": "\(usedToken.sessionID)"])
            return SessionTokens(
                accessToken: accessToken,
                accessTokenExpirationDate: identity.expirationDate,
                refreshToken: successor.value
            )
        } catch let error as RefreshSessionUseCaseError {
            throw error
        } catch SessionRepositoryError.sessionEnded {
            logger.warning("Refresh refused: the session ended while the token was used")
            throw .refreshTokenRejected
        } catch is CancellationError {
            throw .unknown
        } catch {
            logger.error("Refresh failed: unknown error", metadata: ["error": "\(error)"])
            throw .unknown
        }
    }
}
