import AuthCore
import PostgresNIO

#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

/// Locks the registration a token was sent for, so two verifications of it take turns.
struct RegistrationByVerificationTokenDigestStatement: PostgresPreparedStatement {
    static let sql = """
        SELECT account_id, display_name, verification_token_id, verification_expiration_date, creation_date
        FROM registrations
        WHERE verification_token_digest = $1
        FOR UPDATE
        """

    let digest: String

    func makeBindings() throws -> PostgresBindings {
        var bindings = PostgresBindings()
        bindings.append(digest)
        return bindings
    }

    func decodeRow(_ row: PostgresRow) throws -> Registration {
        try Registration(row: row)
    }
}
