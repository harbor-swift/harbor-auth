// Copyright (c) 2026 Zaid Rahhawi
// SPDX-License-Identifier: MIT
// See LICENSE for license information.

package enum RegisterUseCaseError: Error, Equatable {
    case invalidIdempotencyKey
    case invalidEmail
    case invalidPassword
    case invalidDisplayName
    case idempotencyConflict
    case duplicateEmail
    case unknown
}
