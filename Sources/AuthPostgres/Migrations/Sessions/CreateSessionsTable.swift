// Copyright (c) 2026 Zaid Rahhawi
// SPDX-License-Identifier: MIT
// See LICENSE for license information.

package import Logging
package import PostgresMigrations
package import PostgresNIO

package struct CreateSessionsTable: DatabaseMigration {
    package init() {}

    package func apply(connection: PostgresConnection, logger: Logger) async throws {
        try await connection.query(
            """
            CREATE TABLE sessions (
                id UUID PRIMARY KEY DEFAULT uuidv7(),
                account_id UUID NOT NULL REFERENCES accounts (id) ON DELETE CASCADE,
                creation_date TIMESTAMPTZ NOT NULL DEFAULT now(),
                end_date TIMESTAMPTZ
            )
            """,
            logger: logger
        )
        // The foreign key's column, so deleting an account doesn't scan every session.
        try await connection.query("CREATE INDEX sessions_account_id_idx ON sessions (account_id)", logger: logger)
    }

    package func revert(connection: PostgresConnection, logger: Logger) async throws {
        try await connection.query("DROP TABLE IF EXISTS sessions", logger: logger)
    }
}
