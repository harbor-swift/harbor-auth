package enum AccountRepositoryError: Error, Equatable {
    /// Another account holds the address.
    case duplicateEmail
    /// The idempotency key created an account for another address.
    case idempotencyConflict
}
