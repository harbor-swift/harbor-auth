import AuthCore
import HarborTesting
import Logging
import Testing

#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

@Suite("SendVerificationEmailUseCase")
struct SendVerificationEmailUseCaseTests {
    private let input = SendVerificationEmailUseCaseInput(accountID: Fixtures.accountID)
    private let policy = RegistrationPolicy(verificationLifetime: .seconds(86_400))

    @Test("Stores a new token's digest and emails the token, keyed by the stored token's id")
    func sendsToken() async throws {
        let accountRepository = MockAccountRepository(accountByID: Fixtures.account(status: .pendingVerification))
        let registrationRepository = MockRegistrationRepository(registration: Fixtures.registration())
        let scope = MockAuthScope(accountRepository: accountRepository, registrationRepository: registrationRepository)
        let sender = MockVerificationEmailSender()
        let send = SendVerificationEmailUseCase(
            database: MockDatabase(scope: scope),
            verificationEmailSender: sender,
            policy: policy,
            logger: Logger(label: "test")
        )

        let email = try await send(input: input)

        #expect(email.recipient == Fixtures.email)
        #expect(registrationRepository.storedTokens.first?.tokenDigest == OpaqueToken.digest(of: email.token))
        #expect(sender.sentEmails.count == 1)
        #expect(sender.sentEmails.first?.idempotencyKey.hasSuffix(Fixtures.tokenID.uuidString.lowercased()) == true)
    }

    @Test("Sends nothing for an address already verified")
    func refusesVerifiedAccount() async {
        let accountRepository = MockAccountRepository(accountByID: Fixtures.account(status: .active))
        let scope = MockAuthScope(accountRepository: accountRepository)
        let sender = MockVerificationEmailSender()
        let send = SendVerificationEmailUseCase(
            database: MockDatabase(scope: scope),
            verificationEmailSender: sender,
            policy: policy,
            logger: Logger(label: "test")
        )

        await #expect(throws: SendVerificationEmailUseCaseError.alreadyVerified) {
            try await send(input: input)
        }
        #expect(sender.sentEmails.isEmpty)
    }
}
