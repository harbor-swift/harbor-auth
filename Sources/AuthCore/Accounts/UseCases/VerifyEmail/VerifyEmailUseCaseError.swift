package enum VerifyEmailUseCaseError: Error, Equatable {
    case invalidToken
    case tokenExpired
    case unknown
}
