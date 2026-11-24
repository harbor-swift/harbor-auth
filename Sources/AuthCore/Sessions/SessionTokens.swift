#if canImport(FoundationEssentials)
package import FoundationEssentials
#else
package import Foundation
#endif

/// What signing in or refreshing hands the caller: an access token for the API, when it expires, and the
/// refresh token that renews it.
package struct SessionTokens: Equatable, Sendable {
    package let accessToken: String
    package let accessTokenExpirationDate: Date
    package let refreshToken: String

    package init(accessToken: String, accessTokenExpirationDate: Date, refreshToken: String) {
        self.accessToken = accessToken
        self.accessTokenExpirationDate = accessTokenExpirationDate
        self.refreshToken = refreshToken
    }
}
