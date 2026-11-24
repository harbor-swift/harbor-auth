package protocol SendVerificationEmailUseCaseScope: Sendable {
    var accountRepository: any AccountRepository { get }
    var registrationRepository: any RegistrationRepository { get }
}
