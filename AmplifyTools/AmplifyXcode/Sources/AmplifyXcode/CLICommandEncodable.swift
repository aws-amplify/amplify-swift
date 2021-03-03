//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import ArgumentParser

private enum CLICommandEncodableKeys: String, CodingKey {
    case commandName
    case abstract
    case parameters
}

protocol CLICommandEncodable: Encodable {
    static var commandName: String { get }
    static var abstract: String { get }
    static var paramsRegistry: CLICommandEncodableParametersRegistry { get }
    init()
}

extension CLICommandEncodable {
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CLICommandEncodableKeys.self)
        try container.encode(Self.commandName, forKey: .commandName)
        try container.encode(Self.abstract, forKey: .abstract)
        try container.encode(Self.paramsRegistry.parameters, forKey: .parameters)
    }
}

// MARK: - ParsableCommand + CLICommandEncodable

extension CLICommandEncodable where Self: ParsableCommand {
    static var commandName: String { Self.configuration.commandName! }
    static var abstract: String { Self.configuration.abstract }
}
