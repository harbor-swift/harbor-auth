// Copyright (c) 2026 Zaid Rahhawi
// SPDX-License-Identifier: MIT
// See LICENSE for license information.

#if canImport(FoundationEssentials)
package import FoundationEssentials
#else
package import Foundation
#endif

/// An account's registration while its address is unverified or its user isn't yet created in Users.
///
/// The verification token itself is never stored: only its digest, which the repository looks it up by.
package struct Registration: Equatable, Sendable {
    package let accountID: UUID
    package let displayName: DisplayName
    package let verificationTokenID: UUID?
    package let verificationExpirationDate: Date?
    package let creationDate: Date

    package init(
        accountID: UUID,
        displayName: DisplayName,
        verificationTokenID: UUID?,
        verificationExpirationDate: Date?,
        creationDate: Date
    ) {
        self.accountID = accountID
        self.displayName = displayName
        self.verificationTokenID = verificationTokenID
        self.verificationExpirationDate = verificationExpirationDate
        self.creationDate = creationDate
    }

    /// Whether the token sent for this registration can no longer verify it. One never sent can't either.
    package func isVerificationExpired(at date: Date) -> Bool {
        guard let verificationExpirationDate else {
            return true
        }

        return verificationExpirationDate <= date
    }
}
