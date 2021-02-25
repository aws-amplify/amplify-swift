//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// Encodable representation of CLI parameter.
enum CLICommandEncodableParameter: Hashable {
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
extension CLICommandEncodableParameter: Encodable {
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
