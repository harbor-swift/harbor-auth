import AuthCore
import Synchronization

#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

/// Records each user it's asked to create, or throws the error it was given.
final class MockUsersClient: UsersClient {
    private let error: (any Error)?
    private let created = Mutex<[(id: UUID, displayName: DisplayName)]>([])

    init(error: (any Error)? = nil) {
        self.error = error
    }

    var createdUsers: [(id: UUID, displayName: DisplayName)] {
        created.withLock { $0 }
    }

    func createUser(id: UUID, displayName: DisplayName) async throws {
        if let error {
            throw error
        }

        created.withLock { $0.append((id, displayName)) }
    }
}
