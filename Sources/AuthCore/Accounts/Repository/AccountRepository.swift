#if canImport(FoundationEssentials)
package import FoundationEssentials
#else
package import Foundation
#endif

/// The persistence of accounts.
package protocol AccountRepository: Sendable {
    /// Creates the account, or returns the one an earlier request with the same idempotency key created for
    /// the same address.
    func create(_ command: CreateAccountCommand) async throws -> Account
    func account(id: UUID) async throws -> Account?
    func account(email: EmailAddress) async throws -> Account?
    /// Moves a pending account to active, or returns `nil` when it isn't pending.
    func markVerified(id: UUID) async throws -> Account?
    /// Deletes an account still pending verification, with its registration, or returns `nil` when it isn't.
    func deletePending(id: UUID) async throws -> Account?
}
