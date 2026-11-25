// Copyright (c) 2026 Zaid Rahhawi
// SPDX-License-Identifier: MIT
// See LICENSE for license information.

package import Logging
package import PostgresMigrations
package import PostgresNIO

package struct CreateRefreshTokensTable: DatabaseMigration {
    package init() {}

    package func apply(connection: PostgresConnection, logger: Logger) async throws {
        try await connection.query(
            """
            CREATE TABLE refresh_tokens (
                id UUID PRIMARY KEY DEFAULT uuidv7(),
                session_id UUID NOT NULL REFERENCES sessions (id) ON DELETE CASCADE,
                digest TEXT NOT NULL,
                status TEXT NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'used')),
                creation_date TIMESTAMPTZ NOT NULL DEFAULT now(),
                CONSTRAINT refresh_tokens_digest_key UNIQUE (digest)
            )
            """,
            logger: logger
        )
        try await connection.query(
            "CREATE INDEX refresh_tokens_session_id_idx ON refresh_tokens (session_id)",
            logger: logger
        )
    }

    package func revert(connection: PostgresConnection, logger: Logger) async throws {
        try await connection.query("DROP TABLE IF EXISTS refresh_tokens", logger: logger)
    }
}
