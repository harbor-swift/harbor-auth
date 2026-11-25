// Copyright (c) 2026 Zaid Rahhawi
// SPDX-License-Identifier: MIT
// See LICENSE for license information.

import AuthCore
import Synchronization

#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

/// Records each email it's asked to send and its idempotency key.
final class MockVerificationEmailSender: VerificationEmailSender {
    private let sent = Mutex<[(recipient: EmailAddress, token: String, idempotencyKey: String)]>([])

    var sentEmails: [(recipient: EmailAddress, token: String, idempotencyKey: String)] {
        sent.withLock { $0 }
    }

    func send(
        to recipient: EmailAddress,
        displayName: DisplayName,
        token: String,
        expirationDate: Date,
        idempotencyKey: String
    ) async throws {
        sent.withLock { $0.append((recipient, token, idempotencyKey)) }
    }
}
