// Copyright (c) 2026 Zaid Rahhawi
// SPDX-License-Identifier: MIT
// See LICENSE for license information.

import AuthCore
import Configuration

extension RegistrationPolicy {
    /// ## Configuration keys
    /// - `verificationLifetimeSeconds` (int, required)
    init(config: ConfigReader) throws {
        let verificationLifetime = try config.requiredInt(forKey: "verificationLifetimeSeconds", as: Duration.self)
        self.init(verificationLifetime: verificationLifetime)
    }
}
