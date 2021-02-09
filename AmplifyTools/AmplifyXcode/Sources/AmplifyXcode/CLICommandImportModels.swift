//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import ArgumentParser
import AmplifyXcodeCore

/// CLI command invoking `CommandImportModels`.
struct CLICommandImportModels: ParsableCommand, CommandExecutable, CLICommandReportable {
    static let configuration = CommandConfiguration(
        commandName: "import-models",
        abstract: CommandImportModels.description
    )

    @Option(name: .shortAndLong, help: "Project base path")
    private var path: String = Process().currentDirectoryPath

    var environment: AmplifyCommandEnvironment {
        CommandEnvironment(basePath: path, fileManager: FileManager.default)
    }

    func run() throws {
        let output = exec(command: CommandImportModels())
        report(result: output)
        if case .failure = output {
            throw ExitCode.failure
        }
    }
}
