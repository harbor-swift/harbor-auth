// Copyright (c) 2026 Zaid Rahhawi
// SPDX-License-Identifier: MIT
// See LICENSE for license information.

package import Logging
package import Persistence

/// Removes an account whose address was never verified, so the address can register again.
///
/// Returns the account as the transaction found it: still pending when this run removed it, active when its
/// address was verified first. A repeat finds no account. Runs on `auth_service`, as the worker.
package struct ExpireRegistrationUseCase<DatabaseType>: ExpireRegistrationUseCaseProtocol
where DatabaseType: Database, DatabaseType.Scope: ExpireRegistrationUseCaseScope {
    private let database: DatabaseType
    private let logger: Logger

    package init(database: DatabaseType, logger: Logger) {
        self.database = database
        self.logger = logger
    }

    package func callAsFunction(
        input: ExpireRegistrationUseCaseInput
    ) async throws(ExpireRegistrationUseCaseError) -> Account {
        do {
            let account = try await database.withTransaction { scope in
                if let removedAccount = try await scope.accountRepository.deletePending(id: input.accountID) {
                    return removedAccount
                }

                guard let account = try await scope.accountRepository.account(id: input.accountID) else {
                    throw ExpireRegistrationUseCaseError.accountNotFound
                }

                return account
            }

            switch account.status {
            case .pendingVerification:
                logger.info("Registration expired", metadata: ["accountID": "\(account.id)"])
            case .active:
                break
            }
            return account
        } catch let error as ExpireRegistrationUseCaseError {
            throw error
        } catch is CancellationError {
            throw .unknown
        } catch {
            logger.error("Expiring the registration failed: unknown error", metadata: ["error": "\(error)"])
            throw .unknown
        }
    }
}
