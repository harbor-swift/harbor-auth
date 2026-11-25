// Copyright (c) 2026 Zaid Rahhawi
// SPDX-License-Identifier: MIT
// See LICENSE for license information.

import AuthCore
import AuthProtos

extension VerifyEmailUseCaseInput {
    init(_ request: Harbor_Auth_V1_VerifyEmailRequest) {
        self.init(token: request.token)
    }
}
