/// Where an account stands: registered and waiting for its address to be verified, or active.
package enum AccountStatus: String, Equatable, Sendable {
    case pendingVerification = "pending_verification"
    case active
}
