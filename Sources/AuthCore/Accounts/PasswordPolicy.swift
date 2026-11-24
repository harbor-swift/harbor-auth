/// What a password must be, and how hard its hash is to compute.
package struct PasswordPolicy: Equatable, Sendable {
    /// bcrypt ignores every byte after the 72nd, so two longer passwords sharing those would both sign in.
    package static let maximumByteCount = 72

    package let minimumLength: Int
    package let bcryptCost: Int

    package init(minimumLength: Int, bcryptCost: Int) {
        self.minimumLength = minimumLength
        self.bcryptCost = bcryptCost
    }

    /// Whether a password is long enough to resist guessing and short enough for bcrypt to use all of it.
    package func accepts(_ password: String) -> Bool {
        password.count >= minimumLength && password.utf8.count <= Self.maximumByteCount
    }
}
