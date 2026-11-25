// Copyright (c) 2026 Zaid Rahhawi
// SPDX-License-Identifier: MIT
// See LICENSE for license information.

import AuthCore
import PostgresNIO

#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

extension Account {
    /// Decodes `id, email, password_hash, status, creation_date, verification_date`.
    init(row: PostgresRow) throws {
        let (id, email, passwordHash, status, creationDate, verificationDate) = try row.decode(
            (UUID, EmailAddress, String, AccountStatus, Date, Date?).self
        )
        self.init(
            id: id,
            email: email,
            passwordHash: passwordHash,
            status: status,
            creationDate: creationDate,
            verificationDate: verificationDate
        )
    }
}
