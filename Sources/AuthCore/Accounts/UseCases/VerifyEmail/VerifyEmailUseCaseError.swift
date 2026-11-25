// Copyright (c) 2026 Zaid Rahhawi
// SPDX-License-Identifier: MIT
// See LICENSE for license information.

package enum VerifyEmailUseCaseError: Error, Equatable {
    case invalidToken
    case tokenExpired
    case unknown
}
