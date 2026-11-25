// Copyright (c) 2026 Zaid Rahhawi
// SPDX-License-Identifier: MIT
// See LICENSE for license information.

package enum ExpireRegistrationUseCaseError: Error, Equatable {
    case accountNotFound
    case unknown
}
