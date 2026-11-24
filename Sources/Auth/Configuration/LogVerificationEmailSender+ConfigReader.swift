import AuthLog
import Configuration
import Logging

extension LogVerificationEmailSender {
    /// ## Configuration keys
    /// - `verificationURL` (string, required): the page the email links to.
    init(config: ConfigReader, logger: Logger) throws {
        let verificationURL = try config.requiredString(forKey: "verificationURL")
        self.init(verificationURL: verificationURL, logger: logger)
    }
}
