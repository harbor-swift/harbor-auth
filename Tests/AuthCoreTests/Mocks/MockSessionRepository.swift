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

/// Answers with the tokens it was given, and records the sessions opened and ended and the tokens added.
final class MockSessionRepository: SessionRepository {
    private let usableToken: RefreshToken?
    private let presentedToken: RefreshToken?
    private let createError: SessionRepositoryError?
    private let addError: SessionRepositoryError?
    private let calls = Mutex<(created: [CreateSessionCommand], added: [AddRefreshTokenCommand], ended: [UUID])>(
        ([], [], [])
    )

    /// - Parameters:
    ///   - usableToken: what `useRefreshToken(digest:)` returns: the token, if it was active.
    ///   - presentedToken: what `refreshToken(digest:)` returns, whatever its status.
    ///   - createError: what `create(_:)` throws, as a guarded insert would.
    ///   - addError: what `addRefreshToken(_:)` throws, as a guarded insert would.
    init(
        usableToken: RefreshToken? = nil,
        presentedToken: RefreshToken? = nil,
        createError: SessionRepositoryError? = nil,
        addError: SessionRepositoryError? = nil
    ) {
        self.usableToken = usableToken
        self.presentedToken = presentedToken
        self.createError = createError
        self.addError = addError
    }

    var createdSessions: [CreateSessionCommand] {
        calls.withLock { $0.created }
    }

    var addedTokens: [AddRefreshTokenCommand] {
        calls.withLock { $0.added }
    }

    var endedSessionIDs: [UUID] {
        calls.withLock { $0.ended }
    }

    func create(_ command: CreateSessionCommand) async throws -> Session {
        calls.withLock { $0.created.append(command) }
        if let createError {
            throw createError
        }

        return Fixtures.session
    }

    func useRefreshToken(digest: String) async throws -> RefreshToken? {
        usableToken
    }

    func refreshToken(digest: String) async throws -> RefreshToken? {
        presentedToken
    }

    func addRefreshToken(_ command: AddRefreshTokenCommand) async throws -> RefreshToken {
        calls.withLock { $0.added.append(command) }
        if let addError {
            throw addError
        }

        return Fixtures.refreshToken(status: .active)
    }

    func end(sessionID: UUID) async throws -> Session? {
        calls.withLock { $0.ended.append(sessionID) }
        return Fixtures.session
    }
}
