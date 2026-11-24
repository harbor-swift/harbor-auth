#if canImport(FoundationEssentials)
package import FoundationEssentials
#else
package import Foundation
#endif

/// A person's credentials: the address they sign in with, the hash of their password, and whether they have
/// proved the address is theirs.
package struct Account: Equatable, Sendable {
    package let id: UUID
    package let email: EmailAddress
    package let passwordHash: String
    package let status: AccountStatus
    package let creationDate: Date
    package let verificationDate: Date?

    package init(
        id: UUID,
        email: EmailAddress,
        passwordHash: String,
        status: AccountStatus,
        creationDate: Date,
        verificationDate: Date?
    ) {
        self.id = id
        self.email = email
        self.passwordHash = passwordHash
        self.status = status
        self.creationDate = creationDate
        self.verificationDate = verificationDate
    }
}
