#if canImport(FoundationEssentials)
package import FoundationEssentials
#else
package import Foundation
#endif

/// The persistence of registrations that are waiting for verification or for their user.
package protocol RegistrationRepository: Sendable {
    /// Creates the account's registration, or returns the one an earlier request made with the same name.
    func create(_ command: CreateRegistrationCommand) async throws -> Registration
    func registration(accountID: UUID) async throws -> Registration?
    /// The registration a verification token was sent for, locked until the transaction ends.
    func registration(verificationTokenDigest: String) async throws -> Registration?
    /// Replaces the registration's token with a new one, or returns `nil` when there's no registration.
    func storeVerificationToken(_ command: StoreVerificationTokenCommand) async throws -> Registration?
    func delete(accountID: UUID) async throws -> Registration?
}
