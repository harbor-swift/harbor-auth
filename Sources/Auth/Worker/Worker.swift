import ArgumentParser

struct Worker: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "worker",
        abstract: "Auth's background work",
        subcommands: [
            Run.self
        ],
        defaultSubcommand: Run.self
    )
}
