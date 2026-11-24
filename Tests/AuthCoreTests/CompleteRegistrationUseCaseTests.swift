import AuthCore
import HarborTesting
import Logging
import Testing

#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

@Suite("CompleteRegistrationUseCase")
struct CompleteRegistrationUseCaseTests {
    private let input = CompleteRegistrationUseCaseInput(accountID: Fixtures.accountID)

    @Test("Creates the user in Users, then forgets the registration")
    func completes() async throws {
        let accountRepository = MockAccountRepository(accountByID: Fixtures.account(status: .active))
        let registrationRepository = MockRegistrationRepository(registration: Fixtures.registration())
        let scope = MockAuthScope(accountRepository: accountRepository, registrationRepository: registrationRepository)
        let usersClient = MockUsersClient()
        let complete = CompleteRegistrationUseCase(
            database: MockDatabase(scope: scope),
            usersClient: usersClient,
            logger: Logger(label: "test")
        )

        try await complete(input: input)

        #expect(usersClient.createdUsers.map(\.id) == [Fixtures.accountID])
        #expect(usersClient.createdUsers.map(\.displayName) == [Fixtures.displayName])
        #expect(registrationRepository.deletedAccountIDs == [Fixtures.accountID])
    }

    @Test("A completed registration does nothing more")
    func doesNothingWhenCompleted() async throws {
        let accountRepository = MockAccountRepository(accountByID: Fixtures.account(status: .active))
        let scope = MockAuthScope(accountRepository: accountRepository)
        let usersClient = MockUsersClient()
        let complete = CompleteRegistrationUseCase(
            database: MockDatabase(scope: scope),
            usersClient: usersClient,
            logger: Logger(label: "test")
        )

        try await complete(input: input)

        #expect(usersClient.createdUsers.isEmpty)
    }

    @Test("Keeps the registration when Users is unavailable, so a retry completes it")
    func reportsUsersUnavailable() async {
        let accountRepository = MockAccountRepository(accountByID: Fixtures.account(status: .active))
        let registrationRepository = MockRegistrationRepository(registration: Fixtures.registration())
        let scope = MockAuthScope(accountRepository: accountRepository, registrationRepository: registrationRepository)
        let complete = CompleteRegistrationUseCase(
            database: MockDatabase(scope: scope),
            usersClient: MockUsersClient(error: UsersClientError.unavailable),
            logger: Logger(label: "test")
        )

        await #expect(throws: CompleteRegistrationUseCaseError.usersUnavailable) {
            try await complete(input: input)
        }
        #expect(registrationRepository.deletedAccountIDs.isEmpty)
    }

    @Test("Refuses an account whose address isn't verified")
    func refusesUnverifiedAccount() async {
        let accountRepository = MockAccountRepository(accountByID: Fixtures.account(status: .pendingVerification))
        let scope = MockAuthScope(accountRepository: accountRepository)
        let complete = CompleteRegistrationUseCase(
            database: MockDatabase(scope: scope),
            usersClient: MockUsersClient(),
            logger: Logger(label: "test")
        )

        await #expect(throws: CompleteRegistrationUseCaseError.accountNotVerified) {
            try await complete(input: input)
        }
    }
}
