import AuthCore
import HarborTesting
import Logging
import Testing

#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

@Suite("SignInUseCase")
struct SignInUseCaseTests {
    private let input = SignInUseCaseInput(email: "Ada@Example.com", password: "correct horse battery")

    private func useCase(
        account: Account?,
        isPasswordCorrect: Bool = true,
        sessionRepository: MockSessionRepository = MockSessionRepository()
    ) -> SignInUseCase<MockDatabase<MockAuthScope>> {
        let accountRepository = MockAccountRepository(accountByEmail: account)
        let scope = MockAuthScope(accountRepository: accountRepository, sessionRepository: sessionRepository)
        return SignInUseCase(
            database: MockDatabase(scope: scope),
            passwordHasher: MockPasswordHasher(isPasswordCorrect: isPasswordCorrect),
            credentialIssuer: MockCredentialIssuer(),
            policy: Fixtures.sessionPolicy,
            logger: Logger(label: "test")
        )
    }

    @Test("Opens a session and issues tokens for an active account")
    func signsIn() async throws {
        let sessionRepository = MockSessionRepository()
        let signIn = useCase(account: Fixtures.account(status: .active), sessionRepository: sessionRepository)

        let tokens = try await signIn(input: input)

        #expect(tokens.accessToken == "access-token-\(Fixtures.accountID.uuidString.lowercased())")
        #expect(tokens.accessTokenExpirationDate > .now)
        #expect(sessionRepository.createdSessions.count == 1)
        // Only the refresh token's digest is stored.
        #expect(
            sessionRepository.createdSessions.first?.refreshTokenDigest == OpaqueToken.digest(of: tokens.refreshToken)
        )
    }

    @Test("An unknown address answers as a wrong password does")
    func refusesUnknownAddress() async {
        let signIn = useCase(account: nil)

        await #expect(throws: SignInUseCaseError.credentialsRejected) {
            try await signIn(input: input)
        }
    }

    @Test("A wrong password is refused")
    func refusesWrongPassword() async {
        let signIn = useCase(account: Fixtures.account(status: .active), isPasswordCorrect: false)

        await #expect(throws: SignInUseCaseError.credentialsRejected) {
            try await signIn(input: input)
        }
    }

    @Test("An unverified address is refused once the password matches")
    func refusesUnverifiedAddress() async {
        let sessionRepository = MockSessionRepository()
        let signIn = useCase(
            account: Fixtures.account(status: .pendingVerification),
            sessionRepository: sessionRepository
        )

        await #expect(throws: SignInUseCaseError.emailNotVerified) {
            try await signIn(input: input)
        }
        #expect(sessionRepository.createdSessions.isEmpty)
    }

    @Test("A malformed address is refused like a wrong one")
    func refusesMalformedAddress() async {
        let signIn = useCase(account: Fixtures.account(status: .active))
        let malformedInput = SignInUseCaseInput(email: "not an address", password: "correct horse battery")

        await #expect(throws: SignInUseCaseError.credentialsRejected) {
            try await signIn(input: malformedInput)
        }
    }

    @Test("An account that stops being active before its session opens is refused as unverified")
    func mapsInactiveAccountAtSessionOpening() async {
        let sessionRepository = MockSessionRepository(createError: .accountInactive)
        let signIn = useCase(account: Fixtures.account(status: .active), sessionRepository: sessionRepository)

        await #expect(throws: SignInUseCaseError.emailNotVerified) {
            try await signIn(input: input)
        }
    }
}
