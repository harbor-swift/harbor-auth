import AuthCore
import HarborTesting
import Logging
import Temporal
import TemporalTestKit
import Testing

#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

/// Starts real workflows on the test server, on a task queue no worker polls, since `TemporalClient` is concrete.
@Suite(.temporalTestServer)
struct RegisterUseCaseTests {
    private let input = RegisterUseCaseInput(
        email: "Ada@Example.com",
        password: "correct horse battery",
        displayName: "Ada Lovelace",
        idempotencyKey: "key-1"
    )
    private let passwordPolicy = PasswordPolicy(minimumLength: 8, bcryptCost: 4)

    /// An account under its own id, so each test's workflow runs on its own.
    private func account(status: AccountStatus) -> Account {
        Account(
            id: UUID(),
            email: Fixtures.email,
            passwordHash: "hash",
            status: status,
            creationDate: .now,
            verificationDate: nil
        )
    }

    private func register(
        _ input: RegisterUseCaseInput,
        accountRepository: MockAccountRepository,
        registrationRepository: MockRegistrationRepository = MockRegistrationRepository(
            registration: Fixtures.registration()
        )
    ) async throws -> Account {
        let testServer = try #require(TemporalTestServer.testServer)
        return try await testServer.withConnectedClient(logger: Logger(label: "test")) { client in
            let scope = MockAuthScope(
                accountRepository: accountRepository,
                registrationRepository: registrationRepository
            )
            let registerUseCase = RegisterUseCase(
                database: MockDatabase(scope: scope),
                passwordHasher: MockPasswordHasher(),
                temporalClient: client,
                taskQueue: "auth-tests-\(UUID().uuidString.lowercased())",
                policy: passwordPolicy,
                logger: Logger(label: "test")
            )
            return try await registerUseCase(input: input)
        }
    }

    @Test("Registers a pending account with its registration")
    func registersPendingAccount() async throws {
        let pendingAccount = account(status: .pendingVerification)
        let accountRepository = MockAccountRepository(createdAccount: pendingAccount)
        let registrationRepository = MockRegistrationRepository(registration: Fixtures.registration())

        let registeredAccount = try await register(
            input,
            accountRepository: accountRepository,
            registrationRepository: registrationRepository
        )

        #expect(registeredAccount == pendingAccount)
        #expect(registrationRepository.createdRegistrations.map(\.accountID) == [pendingAccount.id])
        #expect(registrationRepository.createdRegistrations.map(\.displayName) == [Fixtures.displayName])
    }

    @Test("A retry after verification gets the account back and creates no registration")
    func retryAfterVerificationCreatesNoRegistration() async throws {
        let activeAccount = account(status: .active)
        let accountRepository = MockAccountRepository(createdAccount: activeAccount)
        let registrationRepository = MockRegistrationRepository()

        let registeredAccount = try await register(
            input,
            accountRepository: accountRepository,
            registrationRepository: registrationRepository
        )

        #expect(registeredAccount == activeAccount)
        #expect(registrationRepository.createdRegistrations.isEmpty)
    }

    @Test(
        "Maps each repository refusal to its case",
        arguments: [
            (AccountRepositoryError.duplicateEmail as any Error, RegisterUseCaseError.duplicateEmail),
            (AccountRepositoryError.idempotencyConflict as any Error, RegisterUseCaseError.idempotencyConflict),
        ]
    )
    func mapsAccountRepositoryErrors(repositoryError: any Error, useCaseError: RegisterUseCaseError) async {
        let accountRepository = MockAccountRepository(createError: repositoryError)

        await #expect(throws: useCaseError) {
            try await register(input, accountRepository: accountRepository)
        }
    }

    @Test("A key reused for another display name is an idempotency conflict")
    func mapsRegistrationIdempotencyConflict() async {
        let accountRepository = MockAccountRepository(createdAccount: account(status: .pendingVerification))
        let registrationRepository = MockRegistrationRepository(
            createError: RegistrationRepositoryError.idempotencyConflict
        )

        await #expect(throws: RegisterUseCaseError.idempotencyConflict) {
            try await register(
                input,
                accountRepository: accountRepository,
                registrationRepository: registrationRepository
            )
        }
    }

    @Test(
        "Refuses invalid input before touching the database",
        arguments: [
            (
                RegisterUseCaseInput(
                    email: "ada@example.com",
                    password: "long enough",
                    displayName: "Ada",
                    idempotencyKey: ""
                ),
                RegisterUseCaseError.invalidIdempotencyKey
            ),
            (
                RegisterUseCaseInput(
                    email: "not-an-address",
                    password: "long enough",
                    displayName: "Ada",
                    idempotencyKey: "k"
                ),
                RegisterUseCaseError.invalidEmail
            ),
            (
                RegisterUseCaseInput(
                    email: "ada@example.com",
                    password: "short",
                    displayName: "Ada",
                    idempotencyKey: "k"
                ),
                RegisterUseCaseError.invalidPassword
            ),
            (
                RegisterUseCaseInput(
                    email: "ada@example.com",
                    password: "long enough",
                    displayName: " ",
                    idempotencyKey: "k"
                ),
                RegisterUseCaseError.invalidDisplayName
            ),
        ]
    )
    func refusesInvalidInput(invalidInput: RegisterUseCaseInput, useCaseError: RegisterUseCaseError) async {
        let accountRepository = MockAccountRepository()

        await #expect(throws: useCaseError) {
            try await register(invalidInput, accountRepository: accountRepository)
        }
    }
}
