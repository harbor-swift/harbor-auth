// Copyright (c) 2026 Zaid Rahhawi
// SPDX-License-Identifier: MIT
// See LICENSE for license information.

import AuthCore

#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

/// Each mock answers with the value it was given, or throws the error it was given.
struct MockRegisterUseCase: RegisterUseCaseProtocol {
    var error: RegisterUseCaseError?

    func callAsFunction(input: RegisterUseCaseInput) async throws(RegisterUseCaseError) -> Account {
        if let error {
            throw error
        }

        let email = EmailAddress(input.email)!
        return Account(
            id: UUID(),
            email: email,
            passwordHash: "hash",
            status: .pendingVerification,
            creationDate: .now,
            verificationDate: nil
        )
    }
}

struct MockVerifyEmailUseCase: VerifyEmailUseCaseProtocol {
    var error: VerifyEmailUseCaseError?

    func callAsFunction(input: VerifyEmailUseCaseInput) async throws(VerifyEmailUseCaseError) {
        if let error {
            throw error
        }
    }
}

struct MockSignInUseCase: SignInUseCaseProtocol {
    var error: SignInUseCaseError?

    func callAsFunction(input: SignInUseCaseInput) async throws(SignInUseCaseError) -> SessionTokens {
        if let error {
            throw error
        }

        return SessionTokens(accessToken: "access", accessTokenExpirationDate: .now, refreshToken: "refresh")
    }
}

struct MockRefreshSessionUseCase: RefreshSessionUseCaseProtocol {
    var error: RefreshSessionUseCaseError?

    func callAsFunction(input: RefreshSessionUseCaseInput) async throws(RefreshSessionUseCaseError) -> SessionTokens {
        if let error {
            throw error
        }

        return SessionTokens(accessToken: "access", accessTokenExpirationDate: .now, refreshToken: "refresh")
    }
}
