// Copyright (c) 2026 Zaid Rahhawi
// SPDX-License-Identifier: MIT
// See LICENSE for license information.

#if canImport(FoundationEssentials)
package import FoundationEssentials
#else
package import Foundation
#endif

/// What Auth needs from Users: a user for each person whose address it has verified.
package protocol UsersClient: Sendable {
    /// Creates the user under their account's id, or does nothing when Users already has them.
    func createUser(id: UUID, displayName: DisplayName) async throws
}
