package import Temporal

#if canImport(FoundationEssentials)
package import FoundationEssentials
#else
package import Foundation
#endif

/// The registration workflow's side effects, each over a system use case.
@ActivityContainer
package struct RegistrationActivities {
    private let sendVerificationEmailUseCase: any SendVerificationEmailUseCaseProtocol
    private let expireRegistrationUseCase: any ExpireRegistrationUseCaseProtocol
    private let completeRegistrationUseCase: any CompleteRegistrationUseCaseProtocol

    package init(
        sendVerificationEmailUseCase: any SendVerificationEmailUseCaseProtocol,
        expireRegistrationUseCase: any ExpireRegistrationUseCaseProtocol,
        completeRegistrationUseCase: any CompleteRegistrationUseCaseProtocol
    ) {
        self.sendVerificationEmailUseCase = sendVerificationEmailUseCase
        self.expireRegistrationUseCase = expireRegistrationUseCase
        self.completeRegistrationUseCase = completeRegistrationUseCase
    }

    // MARK: - Send the verification email

    package struct SendVerificationEmailInput: Codable, Sendable {
        package let accountID: UUID

        package init(accountID: UUID) {
            self.accountID = accountID
        }
    }

    package struct SendVerificationEmailOutput: Codable, Sendable {
        package let expirationDate: Date

        package init(expirationDate: Date) {
            self.expirationDate = expirationDate
        }
    }

    /// Reports when the emailed link expires, or now when the address was verified before a link was needed.
    @Activity
    package func sendVerificationEmail(input: SendVerificationEmailInput) async throws -> SendVerificationEmailOutput {
        do {
            let useCaseInput = SendVerificationEmailUseCaseInput(accountID: input.accountID)
            let email = try await sendVerificationEmailUseCase(input: useCaseInput)
            return SendVerificationEmailOutput(expirationDate: email.expirationDate)
        } catch {
            switch error {
            case .accountNotFound:
                throw ApplicationError(
                    message: "The account does not exist.",
                    type: "AccountNotFound",
                    isNonRetryable: true
                )
            case .alreadyVerified:
                return SendVerificationEmailOutput(expirationDate: .now)
            case .unknown:
                throw error
            }
        }
    }

    // MARK: - Expire the registration

    package struct ExpireRegistrationInput: Codable, Sendable {
        package let accountID: UUID

        package init(accountID: UUID) {
            self.accountID = accountID
        }
    }

    /// Reports whether the account was removed, or kept because its address was verified before the link expired.
    @Activity
    package func expireRegistration(input: ExpireRegistrationInput) async throws -> Bool {
        do {
            let useCaseInput = ExpireRegistrationUseCaseInput(accountID: input.accountID)
            let account = try await expireRegistrationUseCase(input: useCaseInput)
            switch account.status {
            case .pendingVerification:
                return true
            case .active:
                return false
            }
        } catch {
            switch error {
            case .accountNotFound:
                // An earlier attempt removed it.
                return true
            case .unknown:
                throw error
            }
        }
    }

    // MARK: - Complete the registration

    package struct CompleteRegistrationInput: Codable, Sendable {
        package let accountID: UUID

        package init(accountID: UUID) {
            self.accountID = accountID
        }
    }

    @Activity
    package func completeRegistration(input: CompleteRegistrationInput) async throws {
        do {
            let useCaseInput = CompleteRegistrationUseCaseInput(accountID: input.accountID)
            try await completeRegistrationUseCase(input: useCaseInput)
        } catch {
            switch error {
            case .accountNotFound:
                throw ApplicationError(
                    message: "The account does not exist.",
                    type: "AccountNotFound",
                    isNonRetryable: true
                )
            case .accountNotVerified:
                throw ApplicationError(
                    message: "The account's address is not verified.",
                    type: "AccountNotVerified",
                    isNonRetryable: true
                )
            case .usersUnavailable, .unknown:
                throw error
            }
        }
    }
}
