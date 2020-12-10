//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import ArgumentParser

/// CLI interface to `CommandImportConfig` command
struct CLICommandImportConfig: ParsableCommand, CommandExecutable, CLICommandReportable {
    static let configuration = CommandConfiguration(
        commandName: "import-config",
        abstract: CommandImportConfig.description
    )

    @Option(name: .shortAndLong, help: "Project base path")
    private var path: String = Process().currentDirectoryPath

    var environment: AmplifyCommandEnvironment {
        CommandEnvironment(basePath: path)
    }

    func run() throws {
        let output = exec(command: CommandImportConfig())
        report(result: output)
    }
}

/// CLI interface entry point `amplify-ios-cli`
struct AmplifyIOS: ParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "Amplify CLI iOS",
        subcommands: [CLICommandImportConfig.self]
    )
}
