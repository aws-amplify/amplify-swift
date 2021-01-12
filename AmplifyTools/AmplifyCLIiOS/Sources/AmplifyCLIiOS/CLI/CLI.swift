//
// Copyright 2018-2021 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import ArgumentParser

/// This module defines a CLI (Command Line Interface) to commands defined in `Core/Commands`.
/// Each "CLI command" defined below is the actual executor of an `AmplifyCommand`, thus it's responsible
/// for providing an environment, instantiate and execute a command.
/// The `CommandExecutable` protocol glues an `AmplifyCommand` and the environment provided by the executor.

/// CLI command invoking `CommandImportConfig`.
struct CLICommandImportConfig: ParsableCommand, CommandExecutable, CLICommandReportable {
    static let configuration = CommandConfiguration(
        commandName: "import-config",
        abstract: CommandImportConfig.description
    )

    @Option(name: .shortAndLong, help: "Project base path")
    private var path: String = Process().currentDirectoryPath

    var environment: AmplifyCommandEnvironment {
        CommandEnvironment(basePath: path, fileManager: FileManager.default)
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
