// Copyright (c) 2026 Zaid Rahhawi
// SPDX-License-Identifier: MIT
// See LICENSE for license information.

package enum SignInUseCaseError: Error, Equatable {
    case credentialsRejected
    case emailNotVerified
    case unknown
}
