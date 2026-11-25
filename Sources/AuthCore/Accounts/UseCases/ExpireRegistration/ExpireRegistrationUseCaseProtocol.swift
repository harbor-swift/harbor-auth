// Copyright (c) 2026 Zaid Rahhawi
// SPDX-License-Identifier: MIT
// See LICENSE for license information.

package protocol ExpireRegistrationUseCaseProtocol: Sendable {
    /// Removes an account whose address was never verified, so the address can register again.
    func callAsFunction(input: ExpireRegistrationUseCaseInput) async throws(ExpireRegistrationUseCaseError) -> Account
}
