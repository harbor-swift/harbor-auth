package enum CompleteRegistrationUseCaseError: Error, Equatable {
    case accountNotFound
    case accountNotVerified
    case usersUnavailable
    case unknown
}
