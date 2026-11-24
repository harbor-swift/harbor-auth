#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

/// The name a person chooses to be shown by, trimmed of surrounding whitespace.
package struct DisplayName: Hashable, Sendable {
    package static let maximumLength = 100

    package let rawValue: String

    package init?(_ value: String) {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, trimmed.count <= Self.maximumLength else {
            return nil
        }

        self.rawValue = trimmed
    }
}
