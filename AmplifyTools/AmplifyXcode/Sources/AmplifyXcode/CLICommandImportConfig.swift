//
//  File.swift
//  
//
//  Created by Costantino, Diego on 2/9/21.
//

import Foundation
import ArgumentParser
import AmplifyXcodeCore

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
