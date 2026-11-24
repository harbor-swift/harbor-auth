import AuthCore
import PostgresNIO

#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

struct AccountByIDStatement: PostgresPreparedStatement {
    static let sql = """
        SELECT id, email, password_hash, status, creation_date, verification_date
        FROM accounts
        WHERE id = $1
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
