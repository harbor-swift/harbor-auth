// Copyright (c) 2026 Zaid Rahhawi
// SPDX-License-Identifier: MIT
// See LICENSE for license information.

package protocol SignInUseCaseProtocol: Sendable {
    /// Opens a session for an active account whose password matches, with an access token and a refresh token.
    func callAsFunction(input: SignInUseCaseInput) async throws(SignInUseCaseError) -> SessionTokens
}
