//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import ArgumentParser
import AmplifyXcodeCore

/// CLI command invoking `CommandImportConfig`.
struct CLICommandImportConfig: ParsableCommand, CommandExecutable, CLICommandReportable, CLICommand {
    static var parameters = Set<CLICommandParameter>()
    static let configuration = CommandConfiguration(
        commandName: "import-config",
        abstract: CommandImportConfig.description
    )

    @Option(name: "path", help: "Project base path", updating: &parameters)
    private var path: String = Process().currentDirectoryPath

    var environment: AmplifyCommandEnvironment {
        CommandEnvironment(basePath: path, fileManager: FileManager.default)
    }

    func run() throws {
        let output = exec(command: CommandImportConfig())
        report(result: output)
        if case .failure = output {
            throw ExitCode.failure
        }
    }
}
