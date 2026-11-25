// Copyright (c) 2026 Zaid Rahhawi
// SPDX-License-Identifier: MIT
// See LICENSE for license information.

#if canImport(FoundationEssentials)
package import FoundationEssentials
#else
package import Foundation
#endif

/// The persistence of sessions and the refresh tokens that keep them going.
package protocol SessionRepository: Sendable {
    /// Opens a session with its first refresh token, for an account that is active.
    func create(_ command: CreateSessionCommand) async throws -> Session
    /// Moves an active refresh token of an open session to used, or returns `nil` when there's none.
    func useRefreshToken(digest: String) async throws -> RefreshToken?
    func refreshToken(digest: String) async throws -> RefreshToken?
    /// Adds a refresh token to a session that is still open.
    func addRefreshToken(_ command: AddRefreshTokenCommand) async throws -> RefreshToken
    /// Ends an open session, or returns `nil` when it has already ended.
    func end(sessionID: UUID) async throws -> Session?
}
