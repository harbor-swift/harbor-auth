import AuthCore
import Temporal
import TemporalTestKit
import Testing

#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

// Serialized: the suite shares one time-skipping server, and a run skipping time to its timer would time out
// another test's activities.
@Suite("RegistrationWorkflow", .temporalTimeSkippingTestServer, .serialized)
struct RegistrationWorkflowTests {
    private let input = RegistrationWorkflow.Input(accountID: Fixtures.accountID)

    private func sentEmail(expiringIn lifetime: TimeInterval) -> VerificationEmail {
        VerificationEmail(
            recipient: Fixtures.email,
            displayName: Fixtures.displayName,
            token: "token",
            expirationDate: Date.now.addingTimeInterval(lifetime)
        )
    }

    /// Runs the workflow to completion against the activities, signalling it first when asked.
    private func run(
        activities: RegistrationActivities,
        signalsVerification: Bool
    ) async throws {
        let testServer = try #require(TemporalTestServer.timeSkippingTestServer)
        let workflowID = RegistrationWorkflow.id(accountID: UUID())
        try await testServer.withWorkerAndClient(
            activities: activities.allActivities,
            workflows: [RegistrationWorkflow.self]
        ) { taskQueue, client in
            let options = WorkflowOptions(id: workflowID, taskQueue: taskQueue)
            let handle = try await client.startWorkflow(
                type: RegistrationWorkflow.self,
                options: options,
                input: input
            )
            if signalsVerification {
                try await handle.signal(signalType: RegistrationWorkflow.VerifyEmail.self)
            }
            try await handle.result()
        }
    }

    @Test("Creates the user once the person verifies, without waiting for the token to expire")
    func completesWhenVerified() async throws {
        let expire = MockExpireRegistrationUseCase(account: Fixtures.account(status: .pendingVerification))
        let complete = MockCompleteRegistrationUseCase()
        let send = MockSendVerificationEmailUseCase(email: sentEmail(expiringIn: 86_400))
        let activities = RegistrationActivities(
            sendVerificationEmailUseCase: send,
            expireRegistrationUseCase: expire,
            completeRegistrationUseCase: complete
        )

        try await run(activities: activities, signalsVerification: true)

        #expect(expire.calls == 0)
        #expect(complete.calls == 1)
    }

    @Test("Removes the account when the token expires unverified, and creates no user")
    func expiresWhenNotVerified() async throws {
        let expire = MockExpireRegistrationUseCase(account: Fixtures.account(status: .pendingVerification))
        let complete = MockCompleteRegistrationUseCase()
        let send = MockSendVerificationEmailUseCase(email: sentEmail(expiringIn: 86_400))
        let activities = RegistrationActivities(
            sendVerificationEmailUseCase: send,
            expireRegistrationUseCase: expire,
            completeRegistrationUseCase: complete
        )

        try await run(activities: activities, signalsVerification: false)

        #expect(expire.calls == 1)
        #expect(complete.calls == 0)
    }

    @Test("Creates the user when the account was verified but the signal was lost")
    func completesWhenSignalLost() async throws {
        let expire = MockExpireRegistrationUseCase(account: Fixtures.account(status: .active))
        let complete = MockCompleteRegistrationUseCase()
        let send = MockSendVerificationEmailUseCase(email: sentEmail(expiringIn: 86_400))
        let activities = RegistrationActivities(
            sendVerificationEmailUseCase: send,
            expireRegistrationUseCase: expire,
            completeRegistrationUseCase: complete
        )

        try await run(activities: activities, signalsVerification: false)

        #expect(expire.calls == 1)
        #expect(complete.calls == 1)
    }

    @Test("Creates the user, keeping the account, when the address was verified before an email was needed")
    func completesWhenAlreadyVerified() async throws {
        let expire = MockExpireRegistrationUseCase(account: Fixtures.account(status: .active))
        let complete = MockCompleteRegistrationUseCase()
        let send = MockSendVerificationEmailUseCase(email: nil)
        let activities = RegistrationActivities(
            sendVerificationEmailUseCase: send,
            expireRegistrationUseCase: expire,
            completeRegistrationUseCase: complete
        )

        try await run(activities: activities, signalsVerification: false)

        #expect(expire.calls == 1)
        #expect(complete.calls == 1)
    }

    @Test("Keeps sending the verification email until it lands")
    func retriesVerificationEmail() async throws {
        let expire = MockExpireRegistrationUseCase(account: Fixtures.account(status: .pendingVerification))
        let complete = MockCompleteRegistrationUseCase()
        let send = MockSendVerificationEmailUseCase(email: sentEmail(expiringIn: 86_400), unknownErrors: 2)
        let activities = RegistrationActivities(
            sendVerificationEmailUseCase: send,
            expireRegistrationUseCase: expire,
            completeRegistrationUseCase: complete
        )

        try await run(activities: activities, signalsVerification: true)

        #expect(send.calls == 3)
        #expect(complete.calls == 1)
    }

    @Test("Creates the user once Users answers again")
    func completesWhenUsersRecovers() async throws {
        let expire = MockExpireRegistrationUseCase(account: Fixtures.account(status: .active))
        let complete = MockCompleteRegistrationUseCase(unavailableCalls: 2)
        let send = MockSendVerificationEmailUseCase(email: nil)
        let activities = RegistrationActivities(
            sendVerificationEmailUseCase: send,
            expireRegistrationUseCase: expire,
            completeRegistrationUseCase: complete
        )

        try await run(activities: activities, signalsVerification: false)

        #expect(complete.calls == 3)
    }

    @Test("Replays the histories recorded from its earlier runs")
    func replaysRecordedHistories() async throws {
        let historiesDirectory = URL(filePath: #filePath)
            .deletingLastPathComponent()
            .appending(path: "Histories/RegistrationWorkflow")
        let historyFiles = try FileManager.default.contentsOfDirectory(
            at: historiesDirectory,
            includingPropertiesForKeys: nil
        )
        let histories = try historyFiles.map { historyFile in
            let historyData = try Data(contentsOf: historyFile)
            let workflowID = historyFile.deletingPathExtension().lastPathComponent
            return try WorkflowHistory.fromJSON(workflowID: workflowID, jsonData: historyData)
        }
        #expect(!histories.isEmpty)

        var configuration = WorkflowReplayer.Configuration()
        configuration.workflows.append(RegistrationWorkflow.self)
        let replayer = WorkflowReplayer(configuration: configuration)
        _ = try await replayer.replayWorkflows(histories: histories)
    }
}
