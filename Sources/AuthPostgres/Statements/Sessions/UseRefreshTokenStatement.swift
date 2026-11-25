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

/// Moves an active refresh token of an open session to used; any other returns no row.
struct UseRefreshTokenStatement: PostgresPreparedStatement {
    static let sql = """
        UPDATE refresh_tokens
        SET status = 'used'
        FROM sessions
        WHERE refresh_tokens.digest = $1
            AND refresh_tokens.status = 'active'
            AND sessions.id = refresh_tokens.session_id
            AND sessions.end_date IS NULL
        RETURNING refresh_tokens.id, refresh_tokens.session_id, sessions.account_id, refresh_tokens.status,
            refresh_tokens.creation_date
        """

    let digest: String

    func makeBindings() throws -> PostgresBindings {
        var bindings = PostgresBindings()
        bindings.append(digest)
        return bindings
    }

    func decodeRow(_ row: PostgresRow) throws -> RefreshToken {
        try RefreshToken(row: row)
    }
}
