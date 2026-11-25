// Copyright (c) 2026 Zaid Rahhawi
// SPDX-License-Identifier: MIT
// See LICENSE for license information.

package struct CreateAccountCommand: Sendable {
    package let email: EmailAddress
    package let passwordHash: String
    package let idempotencyKey: String

    package init(email: EmailAddress, passwordHash: String, idempotencyKey: String) {
        self.email = email
        self.passwordHash = passwordHash
        self.idempotencyKey = idempotencyKey
    }
}
