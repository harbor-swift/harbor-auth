// Copyright (c) 2026 Zaid Rahhawi
// SPDX-License-Identifier: MIT
// See LICENSE for license information.

import ArgumentParser

@main
struct Auth: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "auth",
        abstract: "The Harbor auth service: accounts, registration, sessions and access tokens",
        subcommands: [
            Serve.self,
            Worker.self,
            Migrate.self,
        ],
        defaultSubcommand: Serve.self
    )
}
