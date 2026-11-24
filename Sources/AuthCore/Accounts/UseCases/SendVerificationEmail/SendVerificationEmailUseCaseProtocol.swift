package protocol SendVerificationEmailUseCaseProtocol: Sendable {
    /// Replaces a pending account's verification token with a new one and emails it.
    func callAsFunction(
        input: SendVerificationEmailUseCaseInput
    ) async throws(SendVerificationEmailUseCaseError) -> VerificationEmail
}
