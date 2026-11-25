// Copyright (c) 2026 Zaid Rahhawi
// SPDX-License-Identifier: MIT
// See LICENSE for license information.

package import Authentication
package import HarborAuthentication
package import Logging
package import Persistence

#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

/// Opens a session for an active account whose password matches, with an access token and a refresh token.
///
/// An unknown address answers as a wrong password does, so signing in reveals nothing about who is
/// registered. Runs on `auth_service`.
package struct SignInUseCase<DatabaseType>: SignInUseCaseProtocol
where DatabaseType: Database, DatabaseType.Scope: SignInUseCaseScope {
    private let database: DatabaseType
    private let passwordHasher: any PasswordHasher
    private let credentialIssuer: any CredentialIssuer<UserIdentity, String>
    private let policy: SessionPolicy
    private let logger: Logger

    package init(
        database: DatabaseType,
        passwordHasher: any PasswordHasher,
        credentialIssuer: any CredentialIssuer<UserIdentity, String>,
        policy: SessionPolicy,
        logger: Logger
    ) {
        self.database = database
        self.passwordHasher = passwordHasher
        self.credentialIssuer = credentialIssuer
        self.policy = policy
        self.logger = logger
    }

    package func callAsFunction(input: SignInUseCaseInput) async throws(SignInUseCaseError) -> SessionTokens {
        guard let email = EmailAddress(input.email) else {
            throw .credentialsRejected
        }

        do {
            let account = try await database.withTransaction { scope in
                try await scope.accountRepository.account(email: email)
            }
            guard let account else {
                logger.warning("Sign-in refused: unknown address")
                throw SignInUseCaseError.credentialsRejected
            }

            let isPasswordCorrect = try await passwordHasher.verify(input.password, hash: account.passwordHash)
            guard isPasswordCorrect else {
                logger.warning("Sign-in refused: wrong password", metadata: ["accountID": "\(account.id)"])
                throw SignInUseCaseError.credentialsRejected
            }

            guard account.status == .active else {
                logger.warning("Sign-in refused: the address isn't verified", metadata: ["accountID": "\(account.id)"])
                throw SignInUseCaseError.emailNotVerified
            }

            let refreshToken = OpaqueToken.generate()
            let command = CreateSessionCommand(accountID: account.id, refreshTokenDigest: refreshToken.digest)
            let session = try await database.withTransaction { scope in
                try await scope.sessionRepository.create(command)
            }

            let issueDate = Date.now
            let identity = policy.identity(userID: account.id, issuedAt: issueDate)
            let accessToken = try await credentialIssuer.issue(for: identity)
            logger.info("Signed in", metadata: ["accountID": "\(account.id)", "sessionID": "\(session.id)"])
            return SessionTokens(
                accessToken: accessToken,
                accessTokenExpirationDate: identity.expirationDate,
                refreshToken: refreshToken.value
            )
        } catch let error as SignInUseCaseError {
            throw error
        } catch SessionRepositoryError.accountInactive {
            logger.warning("Sign-in refused: the account stopped being active")
            throw .emailNotVerified
        } catch is CancellationError {
            throw .unknown
        } catch {
            logger.error("Sign-in failed: unknown error", metadata: ["error": "\(error)"])
            throw .unknown
        }
    }
}
