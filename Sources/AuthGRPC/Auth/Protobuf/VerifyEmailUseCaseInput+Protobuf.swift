import AuthCore
import AuthProtos

extension VerifyEmailUseCaseInput {
    init(_ request: Harbor_Auth_V1_VerifyEmailRequest) {
        self.init(token: request.token)
    }
}
