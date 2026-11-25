// Copyright (c) 2026 Zaid Rahhawi
// SPDX-License-Identifier: MIT
// See LICENSE for license information.

package protocol SignInUseCaseScope: Sendable {
    var accountRepository: any AccountRepository { get }
    var sessionRepository: any SessionRepository { get }
}
