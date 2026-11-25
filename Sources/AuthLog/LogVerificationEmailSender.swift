// Copyright (c) 2026 Zaid Rahhawi
// SPDX-License-Identifier: MIT
// See LICENSE for license information.

package import AuthCore
package import Logging

#if canImport(FoundationEssentials)
package import FoundationEssentials
#else
package import Foundation
#endif

/// A fake email provider for local runs: it writes each verification email to the log instead of sending it.
///
/// It logs the recipient and the token, which nothing else in the system does; a real provider replaces it
/// behind the same port before anything is deployed.
package struct LogVerificationEmailSender: VerificationEmailSender {
    private let verificationURL: String
    private let logger: Logger

    /// - Parameter verificationURL: the page the email links to, which receives the token as `?token=`.
    package init(verificationURL: String, logger: Logger) {
        self.verificationURL = verificationURL
        self.logger = logger
    }

    package func send(
        to recipient: EmailAddress,
        displayName: DisplayName,
        token: String,
        expirationDate: Date,
        idempotencyKey: String
    ) async throws {
        let link = "\(verificationURL)?token=\(token)"
        let formattedExpirationDate = expirationDate.formatted(.iso8601)
        logger.notice(
            """
            [fake email] Verification email (logged, not delivered)
                To: \(displayName.rawValue) <\(recipient.rawValue)>
                Subject: Verify your email address
                Hi \(displayName.rawValue), confirm this address by opening \(link)
                or by sending this token to POST /v1/account/verify-email: \(token)
                The token expires at \(formattedExpirationDate).
            """,
            metadata: ["idempotencyKey": "\(idempotencyKey)"]
        )
    }
}
