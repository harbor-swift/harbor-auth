#if canImport(FoundationEssentials)
package import FoundationEssentials
#else
package import Foundation
#endif

package struct StoreVerificationTokenCommand: Sendable {
    package let accountID: UUID
    package let tokenDigest: String
    package let expirationDate: Date

    package init(accountID: UUID, tokenDigest: String, expirationDate: Date) {
        self.accountID = accountID
        self.tokenDigest = tokenDigest
        self.expirationDate = expirationDate
    }
}
