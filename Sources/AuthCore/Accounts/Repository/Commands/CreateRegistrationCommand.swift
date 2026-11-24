#if canImport(FoundationEssentials)
package import FoundationEssentials
#else
package import Foundation
#endif

package struct CreateRegistrationCommand: Sendable {
    package let accountID: UUID
    package let displayName: DisplayName

    package init(accountID: UUID, displayName: DisplayName) {
        self.accountID = accountID
        self.displayName = displayName
    }
}
