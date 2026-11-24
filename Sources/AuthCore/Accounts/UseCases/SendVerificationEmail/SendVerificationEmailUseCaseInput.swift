#if canImport(FoundationEssentials)
package import FoundationEssentials
#else
package import Foundation
#endif

package struct SendVerificationEmailUseCaseInput: Sendable {
    package let accountID: UUID

    package init(accountID: UUID) {
        self.accountID = accountID
    }
}
