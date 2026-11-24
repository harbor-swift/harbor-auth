package enum SignInUseCaseError: Error, Equatable {
    case credentialsRejected
    case emailNotVerified
    case unknown
}
