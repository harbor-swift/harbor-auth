// Copyright (c) 2026 Zaid Rahhawi
// SPDX-License-Identifier: MIT
// See LICENSE for license information.

import AuthCore
import Synchronization

#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

/// Answers with the registration it was given, and records the registrations created, tokens stored and rows
/// deleted.
final class MockRegistrationRepository: RegistrationRepository {
    private let registration: Registration?
    private let createError: (any Error)?
    private let calls = Mutex<
        (created: [CreateRegistrationCommand], storedTokens: [StoreVerificationTokenCommand], deletedAccountIDs: [UUID])
    >(([], [], []))

    init(registration: Registration? = nil, createError: (any Error)? = nil) {
        self.registration = registration
        self.createError = createError
    }

    var createdRegistrations: [CreateRegistrationCommand] {
        calls.withLock { $0.created }
    }

    var storedTokens: [StoreVerificationTokenCommand] {
        calls.withLock { $0.storedTokens }
    }

    var deletedAccountIDs: [UUID] {
        calls.withLock { $0.deletedAccountIDs }
    }

    func create(_ command: CreateRegistrationCommand) async throws -> Registration {
        calls.withLock { $0.created.append(command) }
        if let createError {
            throw createError
        }

        guard let registration else {
            throw UnexpectedCall()
        }

        return registration
    }

    func registration(accountID: UUID) async throws -> Registration? {
        registration
    }

    func registration(verificationTokenDigest: String) async throws -> Registration? {
        registration
    }

    func storeVerificationToken(_ command: StoreVerificationTokenCommand) async throws -> Registration? {
        calls.withLock { $0.storedTokens.append(command) }
        return registration
    }

    func delete(accountID: UUID) async throws -> Registration? {
        calls.withLock { $0.deletedAccountIDs.append(accountID) }
        return registration
    }
}
