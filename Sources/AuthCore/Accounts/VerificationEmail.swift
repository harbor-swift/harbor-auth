// Copyright (c) 2026 Zaid Rahhawi
// SPDX-License-Identifier: MIT
// See LICENSE for license information.

#if canImport(FoundationEssentials)
package import FoundationEssentials
#else
package import Foundation
#endif

/// The email that asked a person to prove an address is theirs: whom it went to, and the token it carried.
package struct VerificationEmail: Equatable, Sendable {
    package let recipient: EmailAddress
    package let displayName: DisplayName
    package let token: String
    package let expirationDate: Date

    package init(recipient: EmailAddress, displayName: DisplayName, token: String, expirationDate: Date) {
        self.recipient = recipient
        self.displayName = displayName
        self.token = token
        self.expirationDate = expirationDate
    }
}
