//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AmplifyFoundation
import Foundation

extension AmplifyFoundation.LogLevel: Codable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let rawString = try? container.decode(String.self).lowercased() {
            switch rawString {
            case "error": self = .error
            case "warn": self = .warn
            case "info": self = .info
            case "debug": self = .debug
            case "verbose": self = .verbose
            case "none": self = .none
            default:
                let context = DecodingError.Context(
                    codingPath: [],
                    debugDescription: "No matching LogLevel found"
                )
                throw DecodingError.valueNotFound(AmplifyFoundation.LogLevel.self, context)
            }
        } else if let rawInt = try? container.decode(Int.self),
                  let value = AmplifyFoundation.LogLevel(rawValue: rawInt) {
            self = value
        } else {
            let context = DecodingError.Context(
                codingPath: [],
                debugDescription: "Unable to decode LogLevel"
            )
            throw DecodingError.dataCorrupted(context)
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }
}

extension AmplifyFoundation.LogLevel {
    /// - Returns: String representation of log level
    var name: String {
        switch self {
        case .error: return "ERROR"
        case .warn: return "WARN"
        case .info: return "INFO"
        case .debug: return "DEBUG"
        case .verbose: return "VERBOSE"
        case .none: return "NONE"
        }
    }
}
