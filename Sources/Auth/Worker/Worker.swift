// Copyright (c) 2026 Zaid Rahhawi
// SPDX-License-Identifier: MIT
// See LICENSE for license information.

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
