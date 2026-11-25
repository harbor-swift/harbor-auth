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

/// Adds a refresh token to a session that is still open; an ended session gets none, and no row comes back.
struct CreateRefreshTokenStatement: PostgresPreparedStatement {
    static let sql = """
        WITH created AS (
            INSERT INTO refresh_tokens (session_id, digest)
            SELECT id, $2 FROM sessions WHERE id = $1 AND end_date IS NULL
            RETURNING id, session_id, status, creation_date
        )
        SELECT created.id, created.session_id, sessions.account_id, created.status, created.creation_date
        FROM created
        JOIN sessions ON sessions.id = created.session_id
        """

    let sessionID: UUID
    let digest: String

    func makeBindings() throws -> PostgresBindings {
        var bindings = PostgresBindings()
        bindings.append(sessionID)
        bindings.append(digest)
        return bindings
    }

    func decodeRow(_ row: PostgresRow) throws -> RefreshToken {
        try RefreshToken(row: row)
    }
}
