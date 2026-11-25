// Copyright (c) 2026 Zaid Rahhawi
// SPDX-License-Identifier: MIT
// See LICENSE for license information.

package import Logging
package import Persistence

/// Creates a verified person's user in Users, under their account's id, then forgets the registration.
///
/// Users creates a user once per id, so a repeat after a lost answer changes nothing there; a repeat after the
/// registration is gone does nothing at all. Runs on `auth_service`, as the worker.
package struct CompleteRegistrationUseCase<DatabaseType>: CompleteRegistrationUseCaseProtocol
where DatabaseType: Database, DatabaseType.Scope: CompleteRegistrationUseCaseScope {
    private let database: DatabaseType
    private let usersClient: any UsersClient
    private let logger: Logger

    package init(database: DatabaseType, usersClient: any UsersClient, logger: Logger) {
        self.database = database
        self.usersClient = usersClient
        self.logger = logger
    }

    package func callAsFunction(
        input: CompleteRegistrationUseCaseInput
    ) async throws(CompleteRegistrationUseCaseError) {
        do {
            let registration = try await database.withTransaction { scope -> Registration? in
                guard let account = try await scope.accountRepository.account(id: input.accountID) else {
                    logger.warning("Completing the registration refused: no such account")
                    throw CompleteRegistrationUseCaseError.accountNotFound
                }

                guard account.status == .active else {
                    logger.warning("Completing the registration refused: the address isn't verified")
                    throw CompleteRegistrationUseCaseError.accountNotVerified
                }

                // A completed registration has no row left: its user exists.
                return try await scope.registrationRepository.registration(accountID: account.id)
            }
            guard let registration else {
                return
            }

            // Users is called between the transactions, never inside one.
            try await usersClient.createUser(id: registration.accountID, displayName: registration.displayName)
            _ = try await database.withTransaction { scope in
                try await scope.registrationRepository.delete(accountID: input.accountID)
            }
            logger.info("Registration completed", metadata: ["accountID": "\(input.accountID)"])
        } catch let error as CompleteRegistrationUseCaseError {
            throw error
        } catch UsersClientError.unavailable {
            logger.warning("Completing the registration failed: Users is unavailable")
            throw .usersUnavailable
        } catch is CancellationError {
            throw .unknown
        } catch {
            logger.error("Completing the registration failed: unknown error", metadata: ["error": "\(error)"])
            throw .unknown
        }
    }
}
