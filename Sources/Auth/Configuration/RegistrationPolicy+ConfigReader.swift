import AuthCore
import Configuration

extension RegistrationPolicy {
    /// ## Configuration keys
    /// - `verificationLifetimeSeconds` (int, required)
    init(config: ConfigReader) throws {
        let verificationLifetime = try config.requiredInt(forKey: "verificationLifetimeSeconds", as: Duration.self)
        self.init(verificationLifetime: verificationLifetime)
    }
}
