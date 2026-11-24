import Configuration
import JWTKit

#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

extension EdDSA.PrivateKey {
    /// The Ed25519 key Auth signs access tokens with, read once at startup.
    ///
    /// ## Configuration keys
    /// - `privateKeyPath` (string, required): the PEM file of the private key, a secret.
    init(config: ConfigReader) throws {
        let privateKeyPath = try config.requiredString(forKey: "privateKeyPath")
        let privateKeyURL = URL(filePath: privateKeyPath)
        let privateKeyData = try Data(contentsOf: privateKeyURL)
        let privateKeyPEM = String(decoding: privateKeyData, as: UTF8.self)
        try self.init(pem: privateKeyPEM)
    }
}
