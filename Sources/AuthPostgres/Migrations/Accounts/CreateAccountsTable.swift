// Copyright (c) 2026 Zaid Rahhawi
// SPDX-License-Identifier: MIT
// See LICENSE for license information.

package import Logging
package import PostgresMigrations
package import PostgresNIO

package struct CreateAccountsTable: DatabaseMigration {
    package init() {}

    package func apply(connection: PostgresConnection, logger: Logger) async throws {
        try await connection.query(
            """
            CREATE TABLE accounts (
                id UUID PRIMARY KEY DEFAULT uuidv7(),
                email TEXT NOT NULL,
                password_hash TEXT NOT NULL,
                status TEXT NOT NULL DEFAULT 'pending_verification'
                    CHECK (status IN ('pending_verification', 'active')),
                idempotency_key TEXT NOT NULL,
                creation_date TIMESTAMPTZ NOT NULL DEFAULT now(),
                verification_date TIMESTAMPTZ,
                CONSTRAINT accounts_email_key UNIQUE (email),
                CONSTRAINT accounts_idempotency_key_key UNIQUE (idempotency_key)
            )
            """,
            logger: logger
        )
    }

    package func revert(connection: PostgresConnection, logger: Logger) async throws {
        try await connection.query("DROP TABLE IF EXISTS accounts", logger: logger)
    }
}
