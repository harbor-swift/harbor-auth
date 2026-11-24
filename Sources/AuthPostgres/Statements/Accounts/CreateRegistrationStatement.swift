import AuthCore
import PostgresNIO

#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

/// Creates an account's registration, or returns the one an earlier request made with the same display name.
struct CreateRegistrationStatement: PostgresPreparedStatement {
    static let sql = """
        INSERT INTO registrations (account_id, display_name)
        VALUES ($1, $2)
        ON CONFLICT ON CONSTRAINT registrations_pkey DO UPDATE
            SET account_id = EXCLUDED.account_id
            WHERE registrations.display_name = EXCLUDED.display_name
        RETURNING account_id, display_name, verification_token_id, verification_expiration_date, creation_date
        """

    let command: CreateRegistrationCommand

    func makeBindings() throws -> PostgresBindings {
        var bindings = PostgresBindings()
        bindings.append(command.accountID)
        bindings.append(command.displayName)
        return bindings
    }

    func decodeRow(_ row: PostgresRow) throws -> Registration {
        try Registration(row: row)
    }
}
