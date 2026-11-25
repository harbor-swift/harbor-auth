// Copyright (c) 2026 Zaid Rahhawi
// SPDX-License-Identifier: MIT
// See LICENSE for license information.

import AuthCore
import AuthProtos
import SwiftProtobuf

#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

extension Harbor_Auth_V1_Account {
    init(_ account: Account) {
        self.init()
        self.id = account.id.uuidString.lowercased()
        self.email = account.email.rawValue
        self.status = Harbor_Auth_V1_AccountStatus(account.status)
        self.creationDate = Google_Protobuf_Timestamp(date: account.creationDate)
    }
}

extension Harbor_Auth_V1_AccountStatus {
    init(_ status: AccountStatus) {
        switch status {
        case .pendingVerification:
            self = .pendingVerification
        case .active:
            self = .active
        }
    }
}
