package struct RefreshSessionUseCaseInput: Sendable {
    package let refreshToken: String

    package init(refreshToken: String) {
        self.refreshToken = refreshToken
    }
}
