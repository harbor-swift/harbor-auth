// Copyright (c) 2026 Zaid Rahhawi
// SPDX-License-Identifier: MIT
// See LICENSE for license information.

import AuthCore
import Testing

@Suite("PasswordPolicy")
struct PasswordPolicyTests {
    private let policy = PasswordPolicy(minimumLength: 8, bcryptCost: 12)

    @Test("Accepts a password between the minimum length and 72 bytes")
    func acceptsPassword() {
        #expect(policy.accepts("correct horse battery"))
    }

    @Test("Refuses a short password")
    func refusesShortPassword() {
        #expect(!policy.accepts("short"))
    }

    @Test("Counts bytes, not characters, against bcrypt's 72-byte limit")
    func refusesOverlongPassword() {
        // 36 characters, 72 bytes: accepted. One more character is 74 bytes.
        let seventyTwoBytes = String(repeating: "é", count: 36)
        #expect(policy.accepts(seventyTwoBytes))
        #expect(!policy.accepts(seventyTwoBytes + "é"))
    }
}
