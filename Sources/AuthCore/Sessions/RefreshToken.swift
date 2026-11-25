// Copyright (c) 2026 Zaid Rahhawi
// SPDX-License-Identifier: MIT
// See LICENSE for license information.

#if canImport(FoundationEssentials)
package import FoundationEssentials
#else
package import Foundation
#endif

/// A stored refresh token, known only by its digest: one per refresh, each used once.
package struct RefreshToken: Equatable, Sendable {
    package let id: UUID
    package let sessionID: UUID
    package let accountID: UUID
    package let status: RefreshTokenStatus
    package let creationDate: Date

    package init(id: UUID, sessionID: UUID, accountID: UUID, status: RefreshTokenStatus, creationDate: Date) {
        self.id = id
        self.sessionID = sessionID
        self.accountID = accountID
        self.status = status
        self.creationDate = creationDate
    }
}
