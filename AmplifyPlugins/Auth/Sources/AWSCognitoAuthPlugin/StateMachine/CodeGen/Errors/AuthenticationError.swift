//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify

enum AuthenticationError: Error {
    case configuration(message: String)
    case service(message: String)
    case unknown(message: String)
}

extension AuthenticationError: AuthErrorConvertible {
    var authError: AuthError {
        switch self {
        case .configuration(let message):
            return .configuration(message, "")
        case .service(let message):
            return .service(message, "")
        case .unknown(let message):
            return .unknown(message)
        }
    }
}

extension AuthenticationError: Equatable {}

extension AuthenticationError: Codable {
    enum CodingKeys: CodingKey {
        case configuration, service, unknown
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        switch self {
        case .configuration(let message):
            try container.encode(message, forKey: .configuration)
        case .service(let message):
            try container.encode(message, forKey: .service)
        case .unknown(let message):
            try container.encode(message, forKey: .unknown)
        }
    }

    init(from decoder: Decoder) throws {
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
            self = .service(message: message)
        case .unknown:
            let message = try container.decode(String.self, forKey: key)
            self = .unknown(message: message)
        }
    }
}
