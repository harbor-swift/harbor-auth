import AuthCore

struct MockAuthScope:
    RegisterUseCaseScope,
    VerifyEmailUseCaseScope,
    SignInUseCaseScope,
    RefreshSessionUseCaseScope,
    SendVerificationEmailUseCaseScope,
    ExpireRegistrationUseCaseScope,
    CompleteRegistrationUseCaseScope
{
    let accountRepository: any AccountRepository
    let registrationRepository: any RegistrationRepository
    let sessionRepository: any SessionRepository

    init(
        accountRepository: any AccountRepository = MockAccountRepository(),
        registrationRepository: any RegistrationRepository = MockRegistrationRepository(),
        sessionRepository: any SessionRepository = MockSessionRepository()
    ) {
        self.accountRepository = accountRepository
        self.registrationRepository = registrationRepository
        self.sessionRepository = sessionRepository
    }
}
