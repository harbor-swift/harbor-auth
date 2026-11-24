package protocol CompleteRegistrationUseCaseProtocol: Sendable {
    /// Creates a verified person's user in Users, then forgets the registration.
    func callAsFunction(input: CompleteRegistrationUseCaseInput) async throws(CompleteRegistrationUseCaseError)
}
