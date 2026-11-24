import AuthCore
import HarborTesting
import Logging
import Testing

#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

@Suite("ExpireRegistrationUseCase")
struct ExpireRegistrationUseCaseTests {
    private let input = ExpireRegistrationUseCaseInput(accountID: Fixtures.accountID)

    private func useCase(accountRepository: MockAccountRepository) -> ExpireRegistrationUseCase<
        MockDatabase<MockAuthScope>
    > {
        let scope = MockAuthScope(accountRepository: accountRepository)
        return ExpireRegistrationUseCase(database: MockDatabase(scope: scope), logger: Logger(label: "test"))
    }

    @Test("Removes an account still pending, returning it as it was")
    func removesPendingAccount() async throws {
        let pendingAccount = Fixtures.account(status: .pendingVerification)
        let expire = useCase(accountRepository: MockAccountRepository(removedAccount: pendingAccount))

        let account = try await expire(input: input)

        #expect(account.status == .pendingVerification)
    }

    @Test("Leaves an account verified in the meantime, reporting it active")
    func keepsVerifiedAccount() async throws {
        let activeAccount = Fixtures.account(status: .active)
        let expire = useCase(accountRepository: MockAccountRepository(accountByID: activeAccount))

        let account = try await expire(input: input)

        #expect(account.status == .active)
    }

    @Test("A repeat finds no account")
    func reportsMissingAccount() async {
        let expire = useCase(accountRepository: MockAccountRepository())

        await #expect(throws: ExpireRegistrationUseCaseError.accountNotFound) {
            try await expire(input: input)
        }
    }
}
