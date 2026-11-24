#if canImport(FoundationEssentials)
package import FoundationEssentials
#else
package import Foundation
#endif

/// A signed-in device's session, which lasts while its refresh tokens are used in turn.
package struct Session: Equatable, Sendable {
    package let id: UUID
    package let accountID: UUID
    package let creationDate: Date
    package let endDate: Date?

    package init(id: UUID, accountID: UUID, creationDate: Date, endDate: Date?) {
        self.id = id
        self.accountID = accountID
        self.creationDate = creationDate
        self.endDate = endDate
    }
}
