import AuthCore
import AuthProtos
import SwiftProtobuf

extension Harbor_Auth_V1_Session {
    init(_ tokens: SessionTokens) {
        self.init()
        self.accessToken = tokens.accessToken
        self.accessTokenExpirationDate = Google_Protobuf_Timestamp(date: tokens.accessTokenExpirationDate)
        self.refreshToken = tokens.refreshToken
    }
}
