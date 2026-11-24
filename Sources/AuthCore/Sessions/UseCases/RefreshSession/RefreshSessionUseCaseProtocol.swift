package protocol RefreshSessionUseCaseProtocol: Sendable {
    /// Trades a refresh token for a new access token and the refresh token that replaces it.
    func callAsFunction(input: RefreshSessionUseCaseInput) async throws(RefreshSessionUseCaseError) -> SessionTokens
}
