package import AuthCore
import HummingbirdBcrypt
import NIOPosix

/// `PasswordHasher` over bcrypt, run on NIO's thread pool, off the cooperative pool.
///
/// `NIOThreadPool.singleton` is borrowed: NIO owns it and nothing here shuts it down.
package struct BcryptPasswordHasher: PasswordHasher {
    private let cost: UInt8

    package init(cost: Int) {
        self.cost = UInt8(clamping: cost)
    }

    package func hash(_ password: String) async throws -> String {
        let cost = self.cost
        return try await NIOThreadPool.singleton.runIfActive {
            Bcrypt.hash(password, cost: cost)
        }
    }

    package func verify(_ password: String, hash: String) async throws -> Bool {
        try await NIOThreadPool.singleton.runIfActive {
            Bcrypt.verify(password, hash: hash)
        }
    }
}
