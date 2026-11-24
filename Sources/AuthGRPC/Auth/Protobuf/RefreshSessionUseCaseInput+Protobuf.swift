import AuthCore
import AuthProtos

extension RefreshSessionUseCaseInput {
    init(_ request: Harbor_Auth_V1_RefreshSessionRequest) {
        self.init(refreshToken: request.refreshToken)
    }
}
