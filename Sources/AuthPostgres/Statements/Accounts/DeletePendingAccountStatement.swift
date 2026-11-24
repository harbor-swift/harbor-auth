import AuthCore
import PostgresNIO

#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

/// Deletes an account still pending verification, and its registration with it; any other returns no row.
struct DeletePendingAccountStatement: PostgresPreparedStatement {
    static let sql = """
        DELETE FROM accounts
        WHERE id = $1 AND status = 'pending_verification'
        RETURNING id, email, password_hash, status, creation_date, verification_date
        """

    let id: UUID

    func makeBindings() throws -> PostgresBindings {
        var bindings = PostgresBindings()
        bindings.append(id)
        return bindings
    }

    func decodeRow(_ row: PostgresRow) throws -> Account {
        try Account(row: row)
    }
}
