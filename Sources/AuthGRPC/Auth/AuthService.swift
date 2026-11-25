// Copyright (c) 2026 Zaid Rahhawi
// SPDX-License-Identifier: MIT
// See LICENSE for license information.

package import AuthCore
package import AuthProtos
package import GRPCCore
package import SwiftProtobuf

/// Accounts and sessions for people, through the gateway.
///
/// Every RPC is anyone's: each carries its own proof, so no handler requires a caller.
package struct AuthService: Harbor_Auth_V1_AuthService.SimpleServiceProtocol {
    private let registerUseCase: any RegisterUseCaseProtocol
    private let verifyEmailUseCase: any VerifyEmailUseCaseProtocol
    private let signInUseCase: any SignInUseCaseProtocol
    private let refreshSessionUseCase: any RefreshSessionUseCaseProtocol

    package init(
        registerUseCase: any RegisterUseCaseProtocol,
        verifyEmailUseCase: any VerifyEmailUseCaseProtocol,
        signInUseCase: any SignInUseCaseProtocol,
        refreshSessionUseCase: any RefreshSessionUseCaseProtocol
    ) {
        self.registerUseCase = registerUseCase
        self.verifyEmailUseCase = verifyEmailUseCase
        self.signInUseCase = signInUseCase
        self.refreshSessionUseCase = refreshSessionUseCase
    }

    // MARK: - Anyone

    package func register(
        request: Harbor_Auth_V1_RegisterRequest,
        context: ServerContext
    ) async throws -> Harbor_Auth_V1_Account {
        let input = RegisterUseCaseInput(request)

        do {
            let account = try await registerUseCase(input: input)
            return Harbor_Auth_V1_Account(account)
        } catch {
            switch error {
            case .invalidIdempotencyKey:
                throw RPCError(code: .invalidArgument, message: "A valid idempotency key is required.")
            case .invalidEmail:
                throw RPCError(code: .invalidArgument, message: "The email address is not valid.")
            case .invalidPassword:
                throw RPCError(
                    code: .invalidArgument,
                    message: "The password must be at least 8 characters and at most 72 bytes."
                )
            case .invalidDisplayName:
                throw RPCError(code: .invalidArgument, message: "The display name must be 1 to 100 characters.")
            case .idempotencyConflict:
                throw RPCError(
                    code: .failedPrecondition,
                    message: "The idempotency key was used to register another address."
                )
            case .duplicateEmail:
                throw RPCError(code: .alreadyExists, message: "The email address is already registered.")
            case .unknown:
                throw RPCError(code: .internalError, message: "The account could not be registered.")
            }
        }
    }

    package func verifyEmail(
        request: Harbor_Auth_V1_VerifyEmailRequest,
        context: ServerContext
    ) async throws -> Google_Protobuf_Empty {
        let input = VerifyEmailUseCaseInput(request)

        do {
            try await verifyEmailUseCase(input: input)
            return Google_Protobuf_Empty()
        } catch {
            switch error {
            case .invalidToken:
                throw RPCError(code: .unauthenticated, message: "The verification token is not valid.")
            case .tokenExpired:
                throw RPCError(
                    code: .failedPrecondition,
                    message: "The verification token has expired; register again."
                )
            case .unknown:
                throw RPCError(code: .internalError, message: "The email address could not be verified.")
            }
        }
    }

    package func signIn(
        request: Harbor_Auth_V1_SignInRequest,
        context: ServerContext
    ) async throws -> Harbor_Auth_V1_Session {
        let input = SignInUseCaseInput(request)

        do {
            let tokens = try await signInUseCase(input: input)
            return Harbor_Auth_V1_Session(tokens)
        } catch {
            switch error {
            case .credentialsRejected:
                throw RPCError(code: .unauthenticated, message: "The email address or password is wrong.")
            case .emailNotVerified:
                throw RPCError(code: .failedPrecondition, message: "The email address has not been verified.")
            case .unknown:
                throw RPCError(code: .internalError, message: "The sign-in could not be completed.")
            }
        }
    }

    package func refreshSession(
        request: Harbor_Auth_V1_RefreshSessionRequest,
        context: ServerContext
    ) async throws -> Harbor_Auth_V1_Session {
        let input = RefreshSessionUseCaseInput(request)

        do {
            let tokens = try await refreshSessionUseCase(input: input)
            return Harbor_Auth_V1_Session(tokens)
        } catch {
            switch error {
            case .refreshTokenRejected:
                throw RPCError(code: .unauthenticated, message: "The refresh token is not valid.")
            case .unknown:
                throw RPCError(code: .internalError, message: "The session could not be refreshed.")
            }
        }
    }
}
