// Copyright (c) 2026 Zaid Rahhawi
// SPDX-License-Identifier: MIT
// See LICENSE for license information.

extension StringProtocol {
    /// The string without the whitespace at either end, newlines included, as `Character.isWhitespace` defines it.
    ///
    /// The standard library's counterpart of Foundation's `trimmingCharacters(in: .whitespacesAndNewlines)`, which
    /// `FoundationEssentials` doesn't have.
    package func trimmingWhitespace() -> String {
        let start = firstIndex { !$0.isWhitespace } ?? endIndex
        let end = lastIndex { !$0.isWhitespace }.map { index(after: $0) } ?? start
        return String(self[start..<end])
    }
}
