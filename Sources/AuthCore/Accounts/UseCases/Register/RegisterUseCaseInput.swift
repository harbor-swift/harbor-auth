package struct RegisterUseCaseInput: Sendable {
    package let email: String
    package let password: String
    package let displayName: String
    package let idempotencyKey: String

    package init(email: String, password: String, displayName: String, idempotencyKey: String) {
        self.email = email
        self.password = password
        self.displayName = displayName
        self.idempotencyKey = idempotencyKey
    }
}
