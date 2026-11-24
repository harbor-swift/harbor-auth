package protocol RegisterUseCaseScope: Sendable {
    var accountRepository: any AccountRepository { get }
    var registrationRepository: any RegistrationRepository { get }
}
