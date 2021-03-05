//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import ArgumentParser

protocol CLICommandInitializable {
    init()
}

private enum CLICommandCodingKeys: String, CodingKey {
    case commandName
    case abstract
    case parameters
}

protocol CLICommand: Encodable, CLICommandInitializable {
    static var commandName: String { get }
    static var abstract: String { get }
    static var parameters: Set<CLICommandParameter> { get }
}

extension CLICommand {
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CLICommandCodingKeys.self)
        try container.encode(Self.commandName, forKey: .commandName)
        try container.encode(Self.abstract, forKey: .abstract)
        try container.encode(Self.parameters, forKey: .parameters)
    }
}

// MARK: - ParsableCommand + CLICommandEncodable

extension CLICommand where Self: ParsableCommand {
    static var commandName: String { Self.configuration.commandName! }
    static var abstract: String { Self.configuration.abstract }
}
