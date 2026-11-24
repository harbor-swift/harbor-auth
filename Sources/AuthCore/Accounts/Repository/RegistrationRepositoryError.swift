package enum RegistrationRepositoryError: Error, Equatable {
    /// The account's registration holds another display name.
    case idempotencyConflict
}
