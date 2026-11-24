import AuthCore
import PostgresNIO

#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

/// Replaces the registration's token, giving it a new id an email provider can deduplicate by.
struct StoreVerificationTokenStatement: PostgresPreparedStatement {
    static let sql = """
        UPDATE registrations
        SET verification_token_id = uuidv7(), verification_token_digest = $2, verification_expiration_date = $3
        WHERE account_id = $1
        RETURNING account_id, display_name, verification_token_id, verification_expiration_date, creation_date
        """

    let command: StoreVerificationTokenCommand

    func makeBindings() throws -> PostgresBindings {
        var bindings = PostgresBindings()
        bindings.append(command.accountID)
        bindings.append(command.tokenDigest)
        bindings.append(command.expirationDate)
        return bindings
    }

    func decodeRow(_ row: PostgresRow) throws -> Registration {
        try Registration(row: row)
    }
}
