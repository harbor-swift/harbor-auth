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

struct AccountByEmailStatement: PostgresPreparedStatement {
    static let sql = """
        SELECT id, email, password_hash, status, creation_date, verification_date
        FROM accounts
        WHERE email = $1
        """

    let email: String

    func makeBindings() throws -> PostgresBindings {
        var bindings = PostgresBindings()
        bindings.append(email)
        return bindings
    }

    func decodeRow(_ row: PostgresRow) throws -> Account {
        try Account(row: row)
    }
}
