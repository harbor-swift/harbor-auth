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

/// Moves a pending account to active; an account in any other state returns no row.
struct MarkAccountVerifiedStatement: PostgresPreparedStatement {
    static let sql = """
        UPDATE accounts
        SET status = 'active', verification_date = now()
        WHERE id = $1 AND status = 'pending_verification'
        RETURNING id, email, password_hash, status, creation_date, verification_date
        """

    let id: UUID

    func makeBindings() throws -> PostgresBindings {
        var bindings = PostgresBindings()
        bindings.append(id)
        return bindings
    }

    func decodeRow(_ row: PostgresRow) throws -> Account {
        try Account(row: row)
    }
}
