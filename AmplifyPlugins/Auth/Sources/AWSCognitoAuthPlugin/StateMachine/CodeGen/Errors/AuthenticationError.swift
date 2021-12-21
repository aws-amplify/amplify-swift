//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

public enum AuthenticationError: Error {
    case configuration(message: String)
    case service(message: String)
}

extension AuthenticationError: Equatable { }

extension AuthenticationError: Codable {
    enum CodingKeys: CodingKey {
        case configuration, service
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        switch self {
        case .configuration(let message):
            try container.encode(message, forKey: .configuration)
        case .service(let message):
            try container.encode(message, forKey: .service)
        }
    }

    public init(from decoder: Decoder) throws {
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
        }
    }

}
