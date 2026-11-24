package protocol SignInUseCaseScope: Sendable {
    var accountRepository: any AccountRepository { get }
    var sessionRepository: any SessionRepository { get }
}
