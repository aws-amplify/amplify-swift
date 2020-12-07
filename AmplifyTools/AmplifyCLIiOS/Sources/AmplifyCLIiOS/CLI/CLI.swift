//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

import ArgumentParser

// MARK: CLICommandInit
struct CLICommandImportConfig: ParsableCommand, CommandExecutable, CLICommandReportable {
    public static let configuration = CommandConfiguration(
        commandName: "import-config",
        abstract: CommandImportConfig.description
    )

    @Option(name: .shortAndLong, help: "Project base path")
    private var path: String = Process().currentDirectoryPath

    var environment: AmplifyCommandEnvironment {
        CommandEnvironment(basePath: URL(fileURLWithPath: path).path)
    }

    func run() throws {
        let output = exec(command: CommandImportConfig())
        report(result: output)
    }

}

struct AmplifyIOS: ParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "Amplify CLI iOS",
        subcommands: [CLICommandImportConfig.self]
    )
}
