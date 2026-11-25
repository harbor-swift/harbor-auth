// Copyright (c) 2026 Zaid Rahhawi
// SPDX-License-Identifier: MIT
// See LICENSE for license information.

/// The name a person chooses to be shown by, trimmed of surrounding whitespace.
package struct DisplayName: Hashable, Sendable {
    package static let maximumLength = 100

    package let rawValue: String

    package init?(_ value: String) {
        let trimmed = value.trimmingWhitespace()
        guard !trimmed.isEmpty, trimmed.count <= Self.maximumLength else {
            return nil
        }

        self.rawValue = trimmed
    }
}
