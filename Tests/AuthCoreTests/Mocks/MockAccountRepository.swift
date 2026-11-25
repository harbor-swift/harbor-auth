// Copyright (c) 2026 Zaid Rahhawi
// SPDX-License-Identifier: MIT
// See LICENSE for license information.

import AuthCore

#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

/// Answers each read with the account it was given, and removes or verifies the ones it was given.
struct MockAccountRepository: AccountRepository {
    var accountByID: Account?
    var accountByEmail: Account?
    var createdAccount: Account?
    var createError: (any Error)?
    var verifiedAccount: Account?
    var removedAccount: Account?

    func create(_ command: CreateAccountCommand) async throws -> Account {
        if let createError {
            throw createError
        }

        guard let createdAccount else {
            throw UnexpectedCall()
        }

        return createdAccount
    }

    func account(id: UUID) async throws -> Account? {
        accountByID
    }

    func account(email: EmailAddress) async throws -> Account? {
        accountByEmail
    }

    func markVerified(id: UUID) async throws -> Account? {
        verifiedAccount
    }

    func deletePending(id: UUID) async throws -> Account? {
        removedAccount
    }
}
