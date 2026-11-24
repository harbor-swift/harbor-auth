import AuthCore
import Configuration

extension SessionPolicy {
    /// ## Configuration keys
    /// - `accessTokenLifetimeSeconds` (int, required), `issuer` (string, required)
    init(config: ConfigReader) throws {
        let accessTokenLifetime = try config.requiredInt(forKey: "accessTokenLifetimeSeconds", as: Duration.self)
        let issuer = try config.requiredString(forKey: "issuer")
        self.init(accessTokenLifetime: accessTokenLifetime, issuer: issuer)
    }
}
