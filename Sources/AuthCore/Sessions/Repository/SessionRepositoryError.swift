// Copyright (c) 2026 Zaid Rahhawi
// SPDX-License-Identifier: MIT
// See LICENSE for license information.

package enum SessionRepositoryError: Error, Equatable {
    /// The account a session would open for isn't active.
    case accountInactive
    /// The session a refresh token would join has ended.
    case sessionEnded
}
