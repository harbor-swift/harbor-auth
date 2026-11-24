import AuthCore
import PostgresNIO

#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

/// Creates an account, or returns the one an earlier request with the same key created for the same address.
struct CreateAccountStatement: PostgresPreparedStatement {
    static let sql = """
        INSERT INTO accounts (email, password_hash, idempotency_key)
        VALUES ($1, $2, $3)
        ON CONFLICT ON CONSTRAINT accounts_idempotency_key_key DO UPDATE
            SET idempotency_key = EXCLUDED.idempotency_key
            WHERE accounts.email = EXCLUDED.email
        RETURNING id, email, password_hash, status, creation_date, verification_date
        """

    let command: CreateAccountCommand

    func makeBindings() throws -> PostgresBindings {
        var bindings = PostgresBindings()
        bindings.append(command.email)
        bindings.append(command.passwordHash)
        bindings.append(command.idempotencyKey)
        return bindings
    }

    func decodeRow(_ row: PostgresRow) throws -> Account {
        try Account(row: row)
    }
}
