// Copyright (c) 2026 Zaid Rahhawi
// SPDX-License-Identifier: MIT
// See LICENSE for license information.

package enum RefreshSessionUseCaseError: Error, Equatable {
    case refreshTokenRejected
    case unknown
}
