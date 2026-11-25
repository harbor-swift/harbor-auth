// Copyright (c) 2026 Zaid Rahhawi
// SPDX-License-Identifier: MIT
// See LICENSE for license information.

#if canImport(FoundationEssentials)
package import FoundationEssentials
#else
package import Foundation
#endif

/// What Auth needs from an email provider: one verification email delivered.
package protocol VerificationEmailSender: Sendable {
    /// Sends the email that carries the token; a repeat with the same idempotency key sends nothing more.
    func send(
        to recipient: EmailAddress,
        displayName: DisplayName,
        token: String,
        expirationDate: Date,
        idempotencyKey: String
    ) async throws
}
