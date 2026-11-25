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

struct RefreshTokenByDigestStatement: PostgresPreparedStatement {
    static let sql = """
        SELECT refresh_tokens.id, refresh_tokens.session_id, sessions.account_id, refresh_tokens.status,
            refresh_tokens.creation_date
        FROM refresh_tokens
        JOIN sessions ON sessions.id = refresh_tokens.session_id
        WHERE refresh_tokens.digest = $1
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
