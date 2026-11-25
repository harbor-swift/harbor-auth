// Copyright (c) 2026 Zaid Rahhawi
// SPDX-License-Identifier: MIT
// See LICENSE for license information.

import AuthCore
import Testing

@Suite("EmailAddress")
struct EmailAddressTests {
    @Test("Trims and lowercases, so one address always reads the same")
    func normalizes() {
        #expect(EmailAddress("  Ada@Example.COM ")?.rawValue == "ada@example.com")
    }

    @Test(
        "Refuses what can't be an address",
        arguments: [
            "", "ada", "ada@", "@example.com", "ada@example", "a b@example.com", "ada@@example.com", "ada@.example.com",
        ]
    )
    func refusesInvalid(value: String) {
        #expect(EmailAddress(value) == nil)
    }
}
