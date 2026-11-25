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

extension Session {
    /// Decodes `id, account_id, creation_date, end_date`.
    init(row: PostgresRow) throws {
        let (id, accountID, creationDate, endDate) = try row.decode((UUID, UUID, Date, Date?).self)
        self.init(id: id, accountID: accountID, creationDate: creationDate, endDate: endDate)
    }
}
