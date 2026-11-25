// Copyright (c) 2026 Zaid Rahhawi
// SPDX-License-Identifier: MIT
// See LICENSE for license information.

#if canImport(FoundationEssentials)
package import FoundationEssentials
#else
package import Foundation
#endif

package struct CreateSessionCommand: Sendable {
    package let accountID: UUID
    package let refreshTokenDigest: String

    package init(accountID: UUID, refreshTokenDigest: String) {
        self.accountID = accountID
        self.refreshTokenDigest = refreshTokenDigest
    }
}
