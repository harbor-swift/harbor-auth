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

/// Ends an open session; one already ended returns no row.
struct EndSessionStatement: PostgresPreparedStatement {
    static let sql = """
        UPDATE sessions
        SET end_date = now()
        WHERE id = $1 AND end_date IS NULL
        RETURNING id, account_id, creation_date, end_date
        """

    let sessionID: UUID

    func makeBindings() throws -> PostgresBindings {
        var bindings = PostgresBindings()
        bindings.append(sessionID)
        return bindings
    }

    func decodeRow(_ row: PostgresRow) throws -> Session {
        try Session(row: row)
    }
}
