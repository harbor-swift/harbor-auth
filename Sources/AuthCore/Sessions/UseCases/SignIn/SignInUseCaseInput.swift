package struct SignInUseCaseInput: Sendable {
    package let email: String
    package let password: String

    package init(email: String, password: String) {
        self.email = email
        self.password = password
    }
}
