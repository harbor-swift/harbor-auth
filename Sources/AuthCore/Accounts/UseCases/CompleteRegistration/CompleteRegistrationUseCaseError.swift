// Copyright (c) 2026 Zaid Rahhawi
// SPDX-License-Identifier: MIT
// See LICENSE for license information.

package enum CompleteRegistrationUseCaseError: Error, Equatable {
    case accountNotFound
    case accountNotVerified
    case usersUnavailable
    case unknown
}
