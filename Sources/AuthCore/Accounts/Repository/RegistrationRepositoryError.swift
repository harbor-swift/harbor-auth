// Copyright (c) 2026 Zaid Rahhawi
// SPDX-License-Identifier: MIT
// See LICENSE for license information.

package enum RegistrationRepositoryError: Error, Equatable {
    /// The account's registration holds another display name.
    case idempotencyConflict
}
