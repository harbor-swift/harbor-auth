// Copyright (c) 2026 Zaid Rahhawi
// SPDX-License-Identifier: MIT
// See LICENSE for license information.

package import Logging
package import PostgresMigrations
package import PostgresNIO

package struct CreateRegistrationsTable: DatabaseMigration {
    package init() {}

    package func apply(connection: PostgresConnection, logger: Logger) async throws {
        try await connection.query(
            """
            CREATE TABLE registrations (
                account_id UUID PRIMARY KEY REFERENCES accounts (id) ON DELETE CASCADE,
                display_name TEXT NOT NULL,
                verification_token_id UUID,
                verification_token_digest TEXT,
                verification_expiration_date TIMESTAMPTZ,
                creation_date TIMESTAMPTZ NOT NULL DEFAULT now(),
                CONSTRAINT registrations_verification_token_digest_key UNIQUE (verification_token_digest)
            )
            """,
            logger: logger
        )
    }

    package func revert(connection: PostgresConnection, logger: Logger) async throws {
        try await connection.query("DROP TABLE IF EXISTS registrations", logger: logger)
    }
}
