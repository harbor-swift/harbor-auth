package enum SendVerificationEmailUseCaseError: Error, Equatable {
    case accountNotFound
    case alreadyVerified
    case unknown
}
