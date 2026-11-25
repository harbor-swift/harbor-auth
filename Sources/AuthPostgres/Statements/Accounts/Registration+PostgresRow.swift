// Copyright (c) 2026 Zaid Rahhawi
// SPDX-License-Identifier: MIT
// See LICENSE for license information.

import AuthCore
import PostgresNIO

#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

extension Registration {
    /// Decodes `account_id, display_name, verification_token_id, verification_expiration_date, creation_date`.
    init(row: PostgresRow) throws {
        let (accountID, displayName, verificationTokenID, verificationExpirationDate, creationDate) =
            try row.decode((UUID, DisplayName, UUID?, Date?, Date).self)
        self.init(
            accountID: accountID,
            displayName: displayName,
            verificationTokenID: verificationTokenID,
            verificationExpirationDate: verificationExpirationDate,
            creationDate: creationDate
        )
    }
}
