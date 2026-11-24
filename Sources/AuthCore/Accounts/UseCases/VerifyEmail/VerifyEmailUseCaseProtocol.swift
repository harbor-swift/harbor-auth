package protocol VerifyEmailUseCaseProtocol: Sendable {
    /// Activates the account a verification token was sent for, and tells its registration's run.
    func callAsFunction(input: VerifyEmailUseCaseInput) async throws(VerifyEmailUseCaseError)
}
