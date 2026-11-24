import AuthCore
import Synchronization

#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

/// Answers `unknown` the number of times it was given, then with the email it was given, or `alreadyVerified` when it
/// was given none, and counts its calls.
final class MockSendVerificationEmailUseCase: SendVerificationEmailUseCaseProtocol {
    private let email: VerificationEmail?
    private let unknownErrors: Int
    private let callCount = Mutex(0)

    init(email: VerificationEmail?, unknownErrors: Int = 0) {
        self.email = email
        self.unknownErrors = unknownErrors
    }

    var calls: Int {
        callCount.withLock { $0 }
    }

    func callAsFunction(
        input: SendVerificationEmailUseCaseInput
    ) async throws(SendVerificationEmailUseCaseError) -> VerificationEmail {
        let call = callCount.withLock { count in
            count += 1
            return count
        }
        guard call > unknownErrors else {
            throw .unknown
        }

        guard let email else {
            throw .alreadyVerified
        }

        return email
    }
}

/// Answers with the account it was given, and counts its calls.
final class MockExpireRegistrationUseCase: ExpireRegistrationUseCaseProtocol {
    private let account: Account
    private let callCount = Mutex(0)

    init(account: Account) {
        self.account = account
    }

    var calls: Int {
        callCount.withLock { $0 }
    }

    func callAsFunction(
        input: ExpireRegistrationUseCaseInput
    ) async throws(ExpireRegistrationUseCaseError) -> Account {
        callCount.withLock { $0 += 1 }
        return account
    }
}

/// Answers `usersUnavailable` the number of times it was given, then completes, and counts its calls.
final class MockCompleteRegistrationUseCase: CompleteRegistrationUseCaseProtocol {
    private let unavailableCalls: Int
    private let callCount = Mutex(0)

    init(unavailableCalls: Int = 0) {
        self.unavailableCalls = unavailableCalls
    }

    var calls: Int {
        callCount.withLock { $0 }
    }

    func callAsFunction(input: CompleteRegistrationUseCaseInput) async throws(CompleteRegistrationUseCaseError) {
        let call = callCount.withLock { count in
            count += 1
            return count
        }
        guard call > unavailableCalls else {
            throw .usersUnavailable
        }
    }
}
