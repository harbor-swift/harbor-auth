import AuthCore
import PostgresNIO

#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

extension RefreshToken {
    /// Decodes `id, session_id, account_id, status, creation_date`.
    init(row: PostgresRow) throws {
        let (id, sessionID, accountID, status, creationDate) = try row.decode(
            (UUID, UUID, UUID, RefreshTokenStatus, Date).self
        )
        self.init(id: id, sessionID: sessionID, accountID: accountID, status: status, creationDate: creationDate)
    }
}
