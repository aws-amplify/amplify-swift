//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import AmplifyXcodeCore
import ArgumentParser

private struct CLISchema: Encodable {
    let abstract = "Auto generated JSON representation of amplify-xcode CLI"
    var commands: [AnyCLICommandEncodable] = []

    init() {
        for command in AmplifyXcode.configuration.subcommands {
            guard let command = command as? CLICommand.Type else {
                continue
            }
            _ = command.init()
            commands.append(AnyCLICommandEncodable(name: command.commandName,
                                                   abstract: command.abstract,
                                                   parameters: command.parameters))
        }
    }
}

struct CLICommandGenerateJSONSchema: ParsableCommand, CommandExecutable, CLICommand {
    static var parameters: Set<CLICommandParameter> = []
    static let configuration = CommandConfiguration(
        commandName: "generate-schema",
        abstract: "Generates a JSON description of the CLI and its commands"
    )

    @Option(name: "output-path", help: "Path to save the output of generated schema file", &parameters)
    private var outputPath: String

    var environment: AmplifyCommandEnvironment {
        CommandEnvironment(basePath: outputPath, fileManager: FileManager.default)
    }

    func run() throws {
        let schema = try JSONEncoder().encode(CLISchema())
        let schemaFileName = "amplify-xcode.json"
        let fullPath = try environment.createFile(atPath: schemaFileName,
                                                  content: String(data: schema, encoding: .utf8)!)
        print("Schema generated at: \(fullPath)")
    }
}
