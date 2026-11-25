// Copyright (c) 2026 Zaid Rahhawi
// SPDX-License-Identifier: MIT
// See LICENSE for license information.

import AuthCore
import HarborTesting
import Logging
import Testing

#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

@Suite("RefreshSessionUseCase")
struct RefreshSessionUseCaseTests {
    private let input = RefreshSessionUseCaseInput(refreshToken: "presented-token")

    private func useCase(sessionRepository: MockSessionRepository) -> RefreshSessionUseCase<MockDatabase<MockAuthScope>>
    {
        let scope = MockAuthScope(sessionRepository: sessionRepository)
        return RefreshSessionUseCase(
            database: MockDatabase(scope: scope),
            credentialIssuer: MockCredentialIssuer(),
            policy: Fixtures.sessionPolicy,
            logger: Logger(label: "test")
        )
    }

    @Test("Trades an active refresh token for new tokens, storing its successor in the same session")
    func refreshes() async throws {
        let sessionRepository = MockSessionRepository(usableToken: Fixtures.refreshToken(status: .active))
        let refresh = useCase(sessionRepository: sessionRepository)

        let tokens = try await refresh(input: input)

        #expect(tokens.refreshToken != input.refreshToken)
        #expect(sessionRepository.addedTokens.first?.sessionID == Fixtures.sessionID)
        #expect(sessionRepository.addedTokens.first?.digest == OpaqueToken.digest(of: tokens.refreshToken))
        #expect(sessionRepository.endedSessionIDs.isEmpty)
    }

    @Test("A used refresh token presented again ends its session")
    func endsSessionOnReuse() async {
        let sessionRepository = MockSessionRepository(presentedToken: Fixtures.refreshToken(status: .used))
        let refresh = useCase(sessionRepository: sessionRepository)

        await #expect(throws: RefreshSessionUseCaseError.refreshTokenRejected) {
            try await refresh(input: input)
        }
        #expect(sessionRepository.endedSessionIDs == [Fixtures.sessionID])
    }

    @Test("An unknown refresh token is refused and ends nothing")
    func refusesUnknownToken() async {
        let sessionRepository = MockSessionRepository()
        let refresh = useCase(sessionRepository: sessionRepository)

        await #expect(throws: RefreshSessionUseCaseError.refreshTokenRejected) {
            try await refresh(input: input)
        }
        #expect(sessionRepository.endedSessionIDs.isEmpty)
    }

    @Test("An empty refresh token is refused")
    func refusesEmptyToken() async {
        let refresh = useCase(sessionRepository: MockSessionRepository())
        let emptyInput = RefreshSessionUseCaseInput(refreshToken: "")

        await #expect(throws: RefreshSessionUseCaseError.refreshTokenRejected) {
            try await refresh(input: emptyInput)
        }
    }

    @Test("A session that ends while its token is used gets no successor, and the token is refused")
    func mapsSessionEndedDuringRefresh() async {
        let sessionRepository = MockSessionRepository(
            usableToken: Fixtures.refreshToken(status: .active),
            addError: .sessionEnded
        )
        let refresh = useCase(sessionRepository: sessionRepository)

        await #expect(throws: RefreshSessionUseCaseError.refreshTokenRejected) {
            try await refresh(input: input)
        }
    }
}
