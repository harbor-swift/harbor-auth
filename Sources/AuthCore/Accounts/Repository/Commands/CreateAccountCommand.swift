package struct CreateAccountCommand: Sendable {
    package let email: EmailAddress
    package let passwordHash: String
    package let idempotencyKey: String

    package init(email: EmailAddress, passwordHash: String, idempotencyKey: String) {
        self.email = email
        self.passwordHash = passwordHash
        self.idempotencyKey = idempotencyKey
    }
}
