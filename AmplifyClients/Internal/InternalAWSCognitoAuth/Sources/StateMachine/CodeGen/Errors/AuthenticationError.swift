//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

package enum AuthenticationError: Error {
    case configuration(message: String)
    case service(message: String, error: Error?)
    case unknown(message: String)
}

extension AuthenticationError: EngineAuthErrorConvertible {
    package var engineError: EngineAuthError {
        switch self {
        case .configuration(let message):
            return .configuration(message, "")
        case .service(let message, let error):
            if let initiateAuthError = error as? EngineAuthErrorConvertible {
                return initiateAuthError.engineError
            } else {
                return .service(message, "", error)
            }
        case .unknown(let message):
            return .unknown(message)
        }
    }
}

extension AuthenticationError: Codable {

    enum CodingKeys: CodingKey {
        case configuration, service, unknown
    }

    package func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        switch self {
        case .configuration(let message):
            try container.encode(message, forKey: .configuration)
        case .service(let message, _):
            try container.encode(message, forKey: .service)
        case .unknown(let message):
            try container.encode(message, forKey: .unknown)
        }
    }

    package init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        guard let key = container.allKeys.first else {
            throw DecodingError.dataCorrupted(
                DecodingError.Context(
                    codingPath: container.codingPath,
                    debugDescription: "Unable to decode"
                )
            )
        }

        switch key {
        case .configuration:
            let message = try container.decode(String.self, forKey: key)
            self = .configuration(message: message)
        case .service:
            let message = try container.decode(String.self, forKey: key)
            self = .service(message: message, error: nil)
        case .unknown:
            let message = try container.decode(String.self, forKey: key)
            self = .unknown(message: message)
        }
    }
}

extension AuthenticationError: Equatable {
    package static func == (lhs: AuthenticationError, rhs: AuthenticationError) -> Bool {
        switch (lhs, rhs) {
        case (.configuration(let lhsMessage), .configuration(let rhsMessage)):
            return lhsMessage == rhsMessage
        case (.service, .service):
            return true
        case (.unknown, .unknown):
            return true
        default:
            return false
        }
    }
}
