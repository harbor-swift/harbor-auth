package enum RegisterUseCaseError: Error, Equatable {
    case invalidIdempotencyKey
    case invalidEmail
    case invalidPassword
    case invalidDisplayName
    case idempotencyConflict
    case duplicateEmail
    case unknown
}
