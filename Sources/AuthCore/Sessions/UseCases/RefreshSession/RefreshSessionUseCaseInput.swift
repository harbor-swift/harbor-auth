// Copyright (c) 2026 Zaid Rahhawi
// SPDX-License-Identifier: MIT
// See LICENSE for license information.

package struct RefreshSessionUseCaseInput: Sendable {
    package let refreshToken: String

    package init(refreshToken: String) {
        self.refreshToken = refreshToken
    }
}
