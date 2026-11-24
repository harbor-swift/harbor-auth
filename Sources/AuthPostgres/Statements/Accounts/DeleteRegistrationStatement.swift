import AuthCore
import PostgresNIO

#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

struct DeleteRegistrationStatement: PostgresPreparedStatement {
    static let sql = """
        DELETE FROM registrations
        WHERE account_id = $1
        RETURNING account_id, display_name, verification_token_id, verification_expiration_date, creation_date
        """

    let accountID: UUID

    func makeBindings() throws -> PostgresBindings {
        var bindings = PostgresBindings()
        bindings.append(accountID)
        return bindings
    }

    func decodeRow(_ row: PostgresRow) throws -> Registration {
        try Registration(row: row)
    }
}
