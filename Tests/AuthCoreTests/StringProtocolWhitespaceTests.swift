// Copyright (c) 2026 Zaid Rahhawi
// SPDX-License-Identifier: MIT
// See LICENSE for license information.

import AuthCore
import Testing

@Suite("StringProtocol.trimmingWhitespace")
struct StringProtocolWhitespaceTests {
    @Test(
        "Removes whitespace and newlines at either end, and keeps what's between",
        arguments: [
            ("Ada", "Ada"),
            ("  Ada Lovelace \n", "Ada Lovelace"),
            ("\t\r\nAda\u{00A0}", "Ada"),
            ("Ada  Lovelace", "Ada  Lovelace"),
            ("", ""),
            (" \n\t ", ""),
        ]
    )
    func trims(value: String, expected: String) {
        #expect(value.trimmingWhitespace() == expected)
    }
}
