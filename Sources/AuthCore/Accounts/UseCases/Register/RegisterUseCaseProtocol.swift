package protocol RegisterUseCaseProtocol: Sendable {
    /// Registers an account pending verification and starts the registration's workflow, which emails the
    /// verification token.
    func callAsFunction(input: RegisterUseCaseInput) async throws(RegisterUseCaseError) -> Account
}
