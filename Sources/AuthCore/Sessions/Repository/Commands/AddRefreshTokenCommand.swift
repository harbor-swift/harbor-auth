// Copyright (c) 2026 Zaid Rahhawi
// SPDX-License-Identifier: MIT
// See LICENSE for license information.

#if canImport(FoundationEssentials)
package import FoundationEssentials
#else
package import Foundation
#endif

package struct AddRefreshTokenCommand: Sendable {
    package let sessionID: UUID
    package let digest: String

    package init(sessionID: UUID, digest: String) {
        self.sessionID = sessionID
        self.digest = digest
    }
}
