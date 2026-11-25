// Copyright (c) 2026 Zaid Rahhawi
// SPDX-License-Identifier: MIT
// See LICENSE for license information.

import AuthCore
import AuthProtos

extension RegisterUseCaseInput {
    /// The use case validates every field, so the wire's values pass through as they are.
    init(_ request: Harbor_Auth_V1_RegisterRequest) {
        self.init(
            email: request.email,
            password: request.password,
            displayName: request.displayName,
            idempotencyKey: request.idempotencyKey
        )
    }
}
