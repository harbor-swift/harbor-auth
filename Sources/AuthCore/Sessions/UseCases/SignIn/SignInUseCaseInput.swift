// Copyright (c) 2026 Zaid Rahhawi
// SPDX-License-Identifier: MIT
// See LICENSE for license information.

package struct SignInUseCaseInput: Sendable {
    package let email: String
    package let password: String

    package init(email: String, password: String) {
        self.email = email
        self.password = password
    }
}
