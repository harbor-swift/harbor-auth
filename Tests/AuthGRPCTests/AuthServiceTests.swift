// Copyright (c) 2026 Zaid Rahhawi
// SPDX-License-Identifier: MIT
// See LICENSE for license information.

import AuthCore
import AuthGRPC
import AuthProtos
import GRPCCore
import SwiftProtobuf
import Testing

@Suite("AuthService")
struct AuthServiceTests {
    private let context = ServerContext(
        descriptor: MethodDescriptor(fullyQualifiedService: "harbor.auth.v1.AuthService", method: "Test"),
        remotePeer: "in-process",
        localPeer: "in-process",
        cancellation: ServerContext.RPCCancellationHandle()
    )

    private func service(
        register: MockRegisterUseCase = MockRegisterUseCase(),
        verifyEmail: MockVerifyEmailUseCase = MockVerifyEmailUseCase(),
        signIn: MockSignInUseCase = MockSignInUseCase(),
        refreshSession: MockRefreshSessionUseCase = MockRefreshSessionUseCase()
    ) -> AuthService {
        AuthService(
            registerUseCase: register,
            verifyEmailUseCase: verifyEmail,
            signInUseCase: signIn,
            refreshSessionUseCase: refreshSession
        )
    }

    @Test("Register answers the account with a lowercase id")
    func registers() async throws {
        let request = Harbor_Auth_V1_RegisterRequest.with {
            $0.email = "ada@example.com"
            $0.password = "correct horse battery"
            $0.displayName = "Ada"
            $0.idempotencyKey = "key"
        }

        let account = try await service().register(request: request, context: context)

        #expect(account.email == "ada@example.com")
        #expect(account.status == .pendingVerification)
        #expect(account.id == account.id.lowercased())
        #expect(account.hasCreationDate)
    }

    @Test(
        "Register maps each refusal to its status",
        arguments: [
            (RegisterUseCaseError.invalidIdempotencyKey, RPCError.Code.invalidArgument),
            (.invalidEmail, .invalidArgument),
            (.invalidPassword, .invalidArgument),
            (.invalidDisplayName, .invalidArgument),
            (.idempotencyConflict, .failedPrecondition),
            (.duplicateEmail, .alreadyExists),
            (.unknown, .internalError),
        ]
    )
    func mapsRegisterErrors(error: RegisterUseCaseError, code: RPCError.Code) async {
        let service = service(register: MockRegisterUseCase(error: error))
        let request = Harbor_Auth_V1_RegisterRequest()

        let thrown = await #expect(throws: RPCError.self) {
            try await service.register(request: request, context: context)
        }

        #expect(thrown?.code == code)
    }

    @Test(
        "VerifyEmail maps each refusal to its status",
        arguments: [
            (VerifyEmailUseCaseError.invalidToken, RPCError.Code.unauthenticated),
            (.tokenExpired, .failedPrecondition),
            (.unknown, .internalError),
        ]
    )
    func mapsVerifyEmailErrors(error: VerifyEmailUseCaseError, code: RPCError.Code) async {
        let service = service(verifyEmail: MockVerifyEmailUseCase(error: error))
        let request = Harbor_Auth_V1_VerifyEmailRequest()

        let thrown = await #expect(throws: RPCError.self) {
            try await service.verifyEmail(request: request, context: context)
        }

        #expect(thrown?.code == code)
    }

    @Test(
        "SignIn maps each refusal to its status",
        arguments: [
            (SignInUseCaseError.credentialsRejected, RPCError.Code.unauthenticated),
            (.emailNotVerified, .failedPrecondition),
            (.unknown, .internalError),
        ]
    )
    func mapsSignInErrors(error: SignInUseCaseError, code: RPCError.Code) async {
        let service = service(signIn: MockSignInUseCase(error: error))
        let request = Harbor_Auth_V1_SignInRequest()

        let thrown = await #expect(throws: RPCError.self) {
            try await service.signIn(request: request, context: context)
        }

        #expect(thrown?.code == code)
    }

    @Test("RefreshSession refuses a rejected token as unauthenticated")
    func mapsRefreshErrors() async {
        let service = service(refreshSession: MockRefreshSessionUseCase(error: .refreshTokenRejected))
        let request = Harbor_Auth_V1_RefreshSessionRequest()

        let thrown = await #expect(throws: RPCError.self) {
            try await service.refreshSession(request: request, context: context)
        }

        #expect(thrown?.code == .unauthenticated)
    }
}
