//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AmplifyXcodeCore
import ArgumentParser
import Foundation

/// CLI command invoking `CommandImportModels`.
struct CLICommandImportModels: ParsableCommand, CommandExecutable, CLICommandReportable, CLICommand {
    static var parameters = Set<CLICommandParameter>()
    static let configuration = CommandConfiguration(
        commandName: "import-models",
        abstract: CommandImportModels.description
    )

    @Option(name: "path", help: "Project base path", updating: &parameters)
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
