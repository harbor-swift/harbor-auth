import AuthCore
import Configuration

extension PasswordPolicy {
    /// ## Configuration keys
    /// - `minimumLength` (int, required), `bcryptCost` (int, required): read strictly, since they govern
    ///   security, with their standard values in the defaults.
    init(config: ConfigReader) throws {
        let minimumLength = try config.requiredInt(forKey: "minimumLength")
        let bcryptCost = try config.requiredInt(forKey: "bcryptCost")
        self.init(minimumLength: minimumLength, bcryptCost: bcryptCost)
    }
}
