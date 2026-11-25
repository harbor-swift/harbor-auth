// Copyright (c) 2026 Zaid Rahhawi
// SPDX-License-Identifier: MIT
// See LICENSE for license information.

package protocol SendVerificationEmailUseCaseProtocol: Sendable {
    /// Replaces a pending account's verification token with a new one and emails it.
    func callAsFunction(
        input: SendVerificationEmailUseCaseInput
    ) async throws(SendVerificationEmailUseCaseError) -> VerificationEmail
}
