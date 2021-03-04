//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// Encodable representation of a CLI command parameter.
/// Commands parameters (options, flags, arguments) are declared as properties on the command type
/// and annotated with `@propertyWrapper`s `@Option`, `@Flag` and `@Argument` provided by `ArgumentParser`.
/// `ArgumentParser` derives parameters names from property names (i.e.,  an`outputPath` option becomes `--output-path`)
/// making thus impossible to reliably generate a JSON representation of a command and its parameters.
/// Therefore we use the following enum to keep track of each parameter and their attributes (name, type and help text).
enum CLICommandParameter: Hashable {
    case option(name: String, type: String, help: String)
    case argument(name: String, type: String, help: String)
    case flag(name: String, type: String, help: String)

    var kind: String {
        switch self {
        case .option:
            return "option"
        case .argument:
            return "argument"
        case .flag:
            return "flag"
        }
    }
}

// MARK: - CLICommandEncodableParameter + Encodable

extension CLICommandParameter: Encodable {
    private enum CodingKeys: CodingKey {
        case kind
        case name
        case type
        case help
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .option(let name, let type, let help),
             .argument(let name, let type, let help),
             .flag(let name, let type, let help):
            try container.encode(name, forKey: .name)
            try container.encode(type, forKey: .type)
            try container.encode(help, forKey: .help)
            try container.encode(kind, forKey: .kind)
        }
    }
}
