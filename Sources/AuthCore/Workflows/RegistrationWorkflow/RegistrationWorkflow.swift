// Copyright (c) 2026 Zaid Rahhawi
// SPDX-License-Identifier: MIT
// See LICENSE for license information.

package import Temporal

#if canImport(FoundationEssentials)
package import FoundationEssentials
#else
package import Foundation
#endif

/// A registration from sign-up to a user in Users: the verification email, a wait for the person to follow its link
/// until the link expires, then their user, or the removal of the account nobody verified.
@Workflow
package struct RegistrationWorkflow {
    package struct Input: Codable, Sendable {
        package let accountID: UUID

        package init(accountID: UUID) {
            self.accountID = accountID
        }
    }

    private var isEmailVerified = false

    package init(input: Input) {}

    package mutating func run(context: WorkflowContext<Self>, input: Input) async throws {
        // Step 1: Email the person a link to verify their address.
        let sendInput = RegistrationActivities.SendVerificationEmailInput(accountID: input.accountID)
        let link = try await context.executeActivity(
            RegistrationActivities.Activities.SendVerificationEmail.self,
            options: .delivery,
            input: sendInput
        )

        // Step 2: Wait for them to follow it, until it expires.
        let isVerified = try await context.condition(until: link.expirationDate) { $0.isEmailVerified }

        // Step 3: Remove the account nobody verified. The account has the last word, so one verified as the link
        // expired is kept.
        if !isVerified {
            let expireInput = RegistrationActivities.ExpireRegistrationInput(accountID: input.accountID)
            let isAccountRemoved = try await context.executeActivity(
                RegistrationActivities.Activities.ExpireRegistration.self,
                options: .database,
                input: expireInput
            )
            if isAccountRemoved {
                return
            }
        }

        // Step 4: Create the person's user in Users.
        let completeInput = RegistrationActivities.CompleteRegistrationInput(accountID: input.accountID)
        try await context.executeActivity(
            RegistrationActivities.Activities.CompleteRegistration.self,
            options: .database,
            input: completeInput
        )
    }

    /// Ends the wait: the address was verified, which the account already records.
    @WorkflowSignal
    package mutating func verifyEmail(input: Void) {
        isEmailVerified = true
    }
}

extension RegistrationWorkflow {
    /// One run per account.
    package static func id(accountID: UUID) -> String {
        "auth-registration-\(accountID.uuidString.lowercased())"
    }
}
