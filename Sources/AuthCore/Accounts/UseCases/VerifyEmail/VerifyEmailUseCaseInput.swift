package struct VerifyEmailUseCaseInput: Sendable {
    package let token: String

    package init(token: String) {
        self.token = token
    }
}
