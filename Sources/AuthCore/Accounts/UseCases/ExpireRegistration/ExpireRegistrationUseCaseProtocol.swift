package protocol ExpireRegistrationUseCaseProtocol: Sendable {
    /// Removes an account whose address was never verified, so the address can register again.
    func callAsFunction(input: ExpireRegistrationUseCaseInput) async throws(ExpireRegistrationUseCaseError) -> Account
}
