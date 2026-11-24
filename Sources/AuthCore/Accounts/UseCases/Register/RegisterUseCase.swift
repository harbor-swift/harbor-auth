package import Logging
package import Persistence
package import Temporal

#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

/// Registers an account pending verification and starts the registration's workflow, which emails the
/// verification token.
///
/// Anyone may register; the idempotency key makes a retried request return the account its first attempt
/// created. Runs on `auth_service`.
package struct RegisterUseCase<DatabaseType>: RegisterUseCaseProtocol
where DatabaseType: Database, DatabaseType.Scope: RegisterUseCaseScope {
    private let database: DatabaseType
    private let passwordHasher: any PasswordHasher
    private let temporalClient: TemporalClient
    private let taskQueue: String
    private let policy: PasswordPolicy
    private let logger: Logger

    package init(
        database: DatabaseType,
        passwordHasher: any PasswordHasher,
        temporalClient: TemporalClient,
        taskQueue: String,
        policy: PasswordPolicy,
        logger: Logger
    ) {
        self.database = database
        self.passwordHasher = passwordHasher
        self.temporalClient = temporalClient
        self.taskQueue = taskQueue
        self.policy = policy
        self.logger = logger
    }

    package func callAsFunction(input: RegisterUseCaseInput) async throws(RegisterUseCaseError) -> Account {
        guard !input.idempotencyKey.isEmpty else {
            throw .invalidIdempotencyKey
        }

        guard let email = EmailAddress(input.email) else {
            throw .invalidEmail
        }

        guard policy.accepts(input.password) else {
            throw .invalidPassword
        }

        guard let displayName = DisplayName(input.displayName) else {
            throw .invalidDisplayName
        }

        do {
            let passwordHash = try await passwordHasher.hash(input.password)

            let accountCommand = CreateAccountCommand(
                email: email,
                passwordHash: passwordHash,
                idempotencyKey: input.idempotencyKey
            )
            let account = try await database.withTransaction { scope in
                // A retry gets back the account its first attempt created.
                let account = try await scope.accountRepository.create(accountCommand)

                // Verification ends the registration's wait, so only a pending account still needs its row.
                guard account.status == .pendingVerification else {
                    return account
                }

                let registrationCommand = CreateRegistrationCommand(accountID: account.id, displayName: displayName)
                _ = try await scope.registrationRepository.create(registrationCommand)
                return account
            }

            let workflowID = RegistrationWorkflow.id(accountID: account.id)
            let workflowOptions = WorkflowOptions(
                id: workflowID,
                taskQueue: taskQueue,
                idReusePolicy: .allowDuplicateFailedOnly,
                idConflictPolicy: .useExisting
            )
            let workflowInput = RegistrationWorkflow.Input(accountID: account.id)

            do {
                _ = try await temporalClient.startWorkflow(
                    type: RegistrationWorkflow.self,
                    options: workflowOptions,
                    input: workflowInput
                )
                logger.info("Account registered", metadata: ["accountID": "\(account.id)"])
                return account
            } catch is WorkflowAlreadyStartedError {
                // A retry after the registration's run completed: its work is done.
                return account
            }
        } catch let error as RegisterUseCaseError {
            throw error
        } catch AccountRepositoryError.duplicateEmail {
            logger.warning("Registration refused: the address is already registered")
            throw .duplicateEmail
        } catch AccountRepositoryError.idempotencyConflict {
            logger.warning("Registration refused: idempotency key reused for another address")
            throw .idempotencyConflict
        } catch RegistrationRepositoryError.idempotencyConflict {
            logger.warning("Registration refused: idempotency key reused for another display name")
            throw .idempotencyConflict
        } catch is CancellationError {
            throw .unknown
        } catch {
            logger.error("Registration failed: unknown error", metadata: ["error": "\(error)"])
            throw .unknown
        }
    }
}
