#if canImport(FoundationEssentials)
package import FoundationEssentials
#else
package import Foundation
#endif

/// How long a person has to verify their address before the registration lapses.
package struct RegistrationPolicy: Equatable, Sendable {
    package let verificationLifetime: Duration

    package init(verificationLifetime: Duration) {
        self.verificationLifetime = verificationLifetime
    }

    /// When a token sent at a given instant stops verifying.
    package func verificationExpirationDate(sentAt sendDate: Date) -> Date {
        let lifetimeSeconds = verificationLifetime / .seconds(1)
        return sendDate.addingTimeInterval(lifetimeSeconds)
    }
}
