// Copyright (c) 2026 Zaid Rahhawi
// SPDX-License-Identifier: MIT
// See LICENSE for license information.

package import Logging
package import Persistence
package import Temporal

#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

/// Activates the account a verification token was sent for, and tells its registration's run.
///
/// The token is its own proof, so anyone may present it. The account changes in this use case's transaction
/// and the signal only wakes the run, which reads the account; a repeat of a verified token signals again,
/// so a signal lost after the first commit still arrives. Runs on `auth_service`.
package struct VerifyEmailUseCase<DatabaseType>: VerifyEmailUseCaseProtocol
where DatabaseType: Database, DatabaseType.Scope: VerifyEmailUseCaseScope {
    private let database: DatabaseType
    private let temporalClient: TemporalClient
    private let taskQueue: String
    private let logger: Logger

    package init(database: DatabaseType, temporalClient: TemporalClient, taskQueue: String, logger: Logger) {
        self.database = database
        self.temporalClient = temporalClient
        self.taskQueue = taskQueue
        self.logger = logger
    }

    package func callAsFunction(input: VerifyEmailUseCaseInput) async throws(VerifyEmailUseCaseError) {
        guard !input.token.isEmpty else {
            throw .invalidToken
        }

        let tokenDigest = OpaqueToken.digest(of: input.token)

        do {
            let account = try await database.withTransaction { scope in
                let registration = try await scope.registrationRepository.registration(
                    verificationTokenDigest: tokenDigest
                )
                guard let registration else {
                    logger.warning("Verification refused: unknown token")
                    throw VerifyEmailUseCaseError.invalidToken
                }

                guard let account = try await scope.accountRepository.account(id: registration.accountID) else {
                    logger.warning("Verification refused: the account no longer exists")
                    throw VerifyEmailUseCaseError.invalidToken
                }

                switch account.status {
                case .active:
                    return account
                case .pendingVerification:
                    let verificationDate = Date.now
                    guard !registration.isVerificationExpired(at: verificationDate) else {
                        logger.warning("Verification refused: the token has expired")
                        throw VerifyEmailUseCaseError.tokenExpired
                    }

                    // The registration's row is locked, so the account is still pending here.
                    guard let verifiedAccount = try await scope.accountRepository.markVerified(id: account.id) else {
                        logger.warning("Verification refused: the account is no longer pending")
                        throw VerifyEmailUseCaseError.invalidToken
                    }

                    return verifiedAccount
                }
            }

            let workflowID = RegistrationWorkflow.id(accountID: account.id)
            let workflowOptions = WorkflowOptions(
                id: workflowID,
                taskQueue: taskQueue,
                idReusePolicy: .allowDuplicateFailedOnly,
                idConflictPolicy: .useExisting
            )
            let workflowInput = RegistrationWorkflow.Input(accountID: account.id)
            _ = try await temporalClient.signalWithStartWorkflow(
                type: RegistrationWorkflow.self,
                input: workflowInput,
                options: workflowOptions,
                signalType: RegistrationWorkflow.VerifyEmail.self
            )
            logger.info("Email address verified", metadata: ["accountID": "\(account.id)"])
        } catch let error as VerifyEmailUseCaseError {
            throw error
        } catch is WorkflowAlreadyStartedError {
            // The registration's run has completed, so nothing waits for the signal.
            return
        } catch is CancellationError {
            throw .unknown
        } catch {
            logger.error("Verification failed: unknown error", metadata: ["error": "\(error)"])
            throw .unknown
        }
    }
}
