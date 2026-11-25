// Copyright (c) 2026 Zaid Rahhawi
// SPDX-License-Identifier: MIT
// See LICENSE for license information.

#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

/// An email address, trimmed and lowercased, so one address always reads the same.
///
/// Validation is deliberately shallow — one `@`, a local part, and a domain with a dot — since only a sent
/// email proves an address. Comparing case-insensitively departs from RFC 5321's case-sensitive local part,
/// as almost every provider does.
package struct EmailAddress: Hashable, Sendable {
    /// RFC 5321's limit on a forward path, less its angle brackets.
    package static let maximumLength = 254

    package let rawValue: String

    package init?(_ value: String) {
        let normalized = value.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let parts = normalized.split(separator: "@", omittingEmptySubsequences: false)
        guard
            normalized.count <= Self.maximumLength,
            parts.count == 2,
            !parts[0].isEmpty,
            parts[1].contains("."),
            !parts[1].hasPrefix("."),
            !parts[1].hasSuffix("."),
            !normalized.contains(where: \.isWhitespace)
        else {
            return nil
        }

        self.rawValue = normalized
    }
}
