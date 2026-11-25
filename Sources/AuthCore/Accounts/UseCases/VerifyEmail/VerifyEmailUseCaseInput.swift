// Copyright (c) 2026 Zaid Rahhawi
// SPDX-License-Identifier: MIT
// See LICENSE for license information.

package struct VerifyEmailUseCaseInput: Sendable {
    package let token: String

    package init(token: String) {
        self.token = token
    }
}
