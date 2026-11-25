// Copyright (c) 2026 Zaid Rahhawi
// SPDX-License-Identifier: MIT
// See LICENSE for license information.

package protocol VerifyEmailUseCaseScope: Sendable {
    var accountRepository: any AccountRepository { get }
    var registrationRepository: any RegistrationRepository { get }
}
