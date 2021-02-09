//
//  File.swift
//  
//
//  Created by Costantino, Diego on 2/9/21.
//

import Foundation
import ArgumentParser
import AmplifyXcodeCore

/// CLI command invoking `CommandImportModels`.
struct CLICommandImportModels: ParsableCommand, CommandExecutable, CLICommandReportable {
    public static let configuration = CommandConfiguration(
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
    }
}
