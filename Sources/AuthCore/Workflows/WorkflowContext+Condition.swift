package import Temporal

#if canImport(FoundationEssentials)
package import FoundationEssentials
#else
package import Foundation
#endif

extension WorkflowContext {
    /// Waits for the condition to hold until the deadline, and reports whether it held.
    ///
    /// Only the deadline ends the wait with `false`: a cancelled run still throws.
    @discardableResult
    package func condition(until deadline: Date, _ condition: (Workflow) -> Bool) async throws -> Bool {
        let timeUntilDeadline = deadline.timeIntervalSince(now)
        let timeToWait = max(timeUntilDeadline, 0)
        do {
            try await timeout(for: .seconds(timeToWait)) {
                try await self.condition(condition)
            }
            return true
        } catch is CanceledError where !Task.isCancelled {
            return false
        }
    }
}
