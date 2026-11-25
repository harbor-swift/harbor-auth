// Copyright (c) 2026 Zaid Rahhawi
// SPDX-License-Identifier: MIT
// See LICENSE for license information.

package import HarborAuthentication

#if canImport(FoundationEssentials)
package import FoundationEssentials
#else
package import Foundation
#endif

/// What an access token says and how long it lives.
///
/// The lifetime bounds how long a changed account reaches services that verify tokens on their own.
package struct SessionPolicy: Equatable, Sendable {
    package let accessTokenLifetime: Duration
    package let issuer: String

    package init(accessTokenLifetime: Duration, issuer: String) {
        self.accessTokenLifetime = accessTokenLifetime
        self.issuer = issuer
    }

    /// The claims of an access token issued now for an account.
    package func identity(userID: UUID, issuedAt issueDate: Date) -> UserIdentity {
        // RFC 7519's NumericDate is whole seconds in practice; some verifiers refuse a fraction.
        let issueSecond = issueDate.timeIntervalSince1970.rounded(.down)
        let wholeIssueDate = Date(timeIntervalSince1970: issueSecond)
        let lifetimeSeconds = accessTokenLifetime / .seconds(1)
        let expirationDate = wholeIssueDate.addingTimeInterval(lifetimeSeconds)
        return UserIdentity(
            userID: userID,
            role: .user,
            issuer: issuer,
            issueDate: wholeIssueDate,
            expirationDate: expirationDate
        )
    }
}
