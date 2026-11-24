package import AuthCore
package import GRPCCore
import SwiftProtobuf
import UsersProtos

#if canImport(FoundationEssentials)
package import FoundationEssentials
#else
package import Foundation
#endif

/// `UsersClient` over Users' internal contract, as this process, proved by its certificate.
package struct GRPCUsersClient<Transport: ClientTransport>: UsersClient {
    private let client: Harbor_Users_V1_UserInternalService.Client<Transport>

    package init(client: GRPCClient<Transport>) {
        self.client = Harbor_Users_V1_UserInternalService.Client(wrapping: client)
    }

    package func createUser(id: UUID, displayName: DisplayName) async throws {
        do {
            let request = Harbor_Users_V1_CreateUserRequest.with {
                $0.id = id.uuidString.lowercased()
                $0.displayName = displayName.rawValue
            }
            _ = try await client.createUser(request)
        } catch let error as RPCError where error.code == .unavailable || error.code == .deadlineExceeded {
            throw UsersClientError.unavailable
        }
    }
}
