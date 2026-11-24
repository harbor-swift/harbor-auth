import AuthCore

#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

/// Values the suites build their mocks from.
enum Fixtures {
    static let accountID = UUID(uuidString: "0193a1b2-c3d4-7e5f-8a9b-0c1d2e3f4a5b")!
    static let sessionID = UUID(uuidString: "0193a1b2-c3d4-7e5f-8a9b-0c1d2e3f4a5c")!
    static let tokenID = UUID(uuidString: "0193a1b2-c3d4-7e5f-8a9b-0c1d2e3f4a5d")!
    static let email = EmailAddress("ada@example.com")!
    static let displayName = DisplayName("Ada Lovelace")!

    static func account(status: AccountStatus) -> Account {
        Account(
            id: accountID,
            email: email,
            passwordHash: "hash",
            status: status,
            creationDate: .now,
            verificationDate: nil
        )
    }

    static func registration(expirationDate: Date? = Date.now.addingTimeInterval(3600)) -> Registration {
        Registration(
            accountID: accountID,
            displayName: displayName,
            verificationTokenID: tokenID,
            verificationExpirationDate: expirationDate,
            creationDate: .now
        )
    }

    static func refreshToken(status: RefreshTokenStatus) -> RefreshToken {
        RefreshToken(id: tokenID, sessionID: sessionID, accountID: accountID, status: status, creationDate: .now)
    }

    static let session = Session(id: sessionID, accountID: accountID, creationDate: .now, endDate: nil)

    static let sessionPolicy = SessionPolicy(accessTokenLifetime: .seconds(900), issuer: "harbor-auth")
}

/// A call a mock wasn't given an answer for.
struct UnexpectedCall: Error {}
