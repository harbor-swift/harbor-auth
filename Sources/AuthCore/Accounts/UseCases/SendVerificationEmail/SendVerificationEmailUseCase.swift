// Copyright (c) 2026 Zaid Rahhawi
// SPDX-License-Identifier: MIT
// See LICENSE for license information.

package import Logging
package import Persistence

#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

/// Replaces a pending account's verification token with a new one and emails it.
///
/// The registration's workflow runs it, so the token never enters the workflow's history: it's made, stored
/// as its digest and sent here. A repeat sends a new token that replaces the last. Runs on `auth_service`, as
/// the worker.
package struct SendVerificationEmailUseCase<DatabaseType>: SendVerificationEmailUseCaseProtocol
where DatabaseType: Database, DatabaseType.Scope: SendVerificationEmailUseCaseScope {
    private let database: DatabaseType
    private let verificationEmailSender: any VerificationEmailSender
    private let policy: RegistrationPolicy
    private let logger: Logger

    package init(
        database: DatabaseType,
        verificationEmailSender: any VerificationEmailSender,
        policy: RegistrationPolicy,
        logger: Logger
    ) {
        self.database = database
        self.verificationEmailSender = verificationEmailSender
        self.policy = policy
        self.logger = logger
    }

    package func callAsFunction(
        input: SendVerificationEmailUseCaseInput
    ) async throws(SendVerificationEmailUseCaseError) -> VerificationEmail {
        let token = OpaqueToken.generate()
        let sendDate = Date.now
        let expirationDate = policy.verificationExpirationDate(sentAt: sendDate)

        do {
            let (email, tokenID) = try await database.withTransaction { scope in
                guard let account = try await scope.accountRepository.account(id: input.accountID) else {
                    logger.warning("Verification email refused: no such account")
                    throw SendVerificationEmailUseCaseError.accountNotFound
                }

                guard account.status == .pendingVerification else {
                    throw SendVerificationEmailUseCaseError.alreadyVerified
                }

                let command = StoreVerificationTokenCommand(
                    accountID: account.id,
                    tokenDigest: token.digest,
                    expirationDate: expirationDate
                )
                let registration = try await scope.registrationRepository.storeVerificationToken(command)
                guard let registration, let tokenID = registration.verificationTokenID else {
                    logger.warning("Verification email refused: the account has no registration")
                    throw SendVerificationEmailUseCaseError.accountNotFound
                }

                let email = VerificationEmail(
                    recipient: account.email,
                    displayName: registration.displayName,
                    token: token.value,
                    expirationDate: expirationDate
                )
                return (email, tokenID)
            }

            // Keyed by the stored token, so a provider retrying a send delivers this token once.
            let idempotencyKey =
                "auth-verification-email-\(input.accountID.uuidString.lowercased())-"
                + tokenID.uuidString.lowercased()
            try await verificationEmailSender.send(
                to: email.recipient,
                displayName: email.displayName,
                token: email.token,
                expirationDate: email.expirationDate,
                idempotencyKey: idempotencyKey
            )
            logger.info("Verification email sent", metadata: ["accountID": "\(input.accountID)"])
            return email
        } catch let error as SendVerificationEmailUseCaseError {
            throw error
        } catch is CancellationError {
            throw .unknown
        } catch {
            logger.error("Sending the verification email failed: unknown error", metadata: ["error": "\(error)"])
            throw .unknown
        }
    }
}
