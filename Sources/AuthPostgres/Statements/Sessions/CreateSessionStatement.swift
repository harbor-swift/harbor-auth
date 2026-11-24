import AuthCore
import PostgresNIO

#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

/// Opens a session for an active account and stores its first refresh token, in one statement; an account
/// that isn't active gets no session, and no row comes back.
struct CreateSessionStatement: PostgresPreparedStatement {
    static let sql = """
        WITH created AS (
            INSERT INTO sessions (account_id)
            SELECT id FROM accounts WHERE id = $1 AND status = 'active'
            RETURNING id, account_id, creation_date, end_date
        ), first_token AS (
            INSERT INTO refresh_tokens (session_id, digest)
            SELECT id, $2 FROM created
        )
        SELECT id, account_id, creation_date, end_date
        FROM created
        """

    let command: CreateSessionCommand

    func makeBindings() throws -> PostgresBindings {
        var bindings = PostgresBindings()
        bindings.append(command.accountID)
        bindings.append(command.refreshTokenDigest)
        return bindings
    }

    func decodeRow(_ row: PostgresRow) throws -> Session {
        try Session(row: row)
    }
}
