import AuthCore
import AuthProtos

extension SignInUseCaseInput {
    init(_ request: Harbor_Auth_V1_SignInRequest) {
        self.init(email: request.email, password: request.password)
    }
}
