//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import AmplifyXcodeCore
import ArgumentParser

private struct CLIBindings: Encodable {
    let abstract = "Auto generated JSON representation of amplify-xcode CLI"
    var commands: [AnyCLICommandEncodable] = []

    init() {
        for command in AmplifyXcode.configuration.subcommands where command != CLICommandGenerateJSONSchema.self {
            if let command = command as? CLICommandEncodable.Type {
                _ = command.init()
                commands.append(AnyCLICommandEncodable(name: command.commandName,
                                                       abstract: command.abstract,
                                                       parameters: command.paramsRegistry.parameters))
            }
        }
    }
}

struct AnyCLICommandEncodable: Encodable {
    let name: String
    let abstract: String
    let parameters: Set<CLICommandEncodableParameter>
}

struct CLICommandGenerateJSONSchema: ParsableCommand, CommandExecutable {
    static var paramsRegistry: CLICommandEncodableRegistry = CLICommandEncodableRegistry()
    static let configuration = CommandConfiguration(
        commandName: "genenerate-bindings",
        abstract: "Generates a JSON description of the CLI and its commands"
    )

    @Option(name: "output-path", help: "Path to save output of generated binding file", paramsRegistry)
    private var outputPath: String = Process().currentDirectoryPath

    var environment: AmplifyCommandEnvironment {
        CommandEnvironment(basePath: outputPath, fileManager: FileManager.default)
    }

    func run() throws {
        let spec = try JSONEncoder().encode(CLIBindings())
        print(String(data: spec, encoding: .utf8)!)
    }
}
