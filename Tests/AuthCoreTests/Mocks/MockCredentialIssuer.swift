import Authentication
import HarborAuthentication

#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

/// Issues a token that names its subject, so a test can tell whose it is.
struct MockCredentialIssuer: CredentialIssuer {
    func issue(for identity: UserIdentity) async throws -> String {
        "access-token-\(identity.userID.uuidString.lowercased())"
    }
}
