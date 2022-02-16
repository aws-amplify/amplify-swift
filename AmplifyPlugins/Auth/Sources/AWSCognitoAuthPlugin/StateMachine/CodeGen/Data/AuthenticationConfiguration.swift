//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

enum AuthenticationConfiguration {
    case userPools(UserPoolConfigurationData)
}

extension AuthenticationConfiguration: Equatable { }

extension AuthenticationConfiguration: Codable {
    enum CodingKeys: CodingKey {
        case userPools
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        switch self {
        case .userPools(let configData):
            try container.encode(configData, forKey: .userPools)
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
        case .userPools:
            let configData = try container.decode(UserPoolConfigurationData.self, forKey: key)
            self = .userPools(configData)
        }
    }

}

extension AuthenticationConfiguration: CustomDebugDictionaryConvertible {
    var debugDictionary: [String: Any] {
        switch self {
        case .userPools(let userPoolConfigurationData):
            return [
                "AuthenticationConfiguration": "userPools",
                "- UserPoolConfigurationData": userPoolConfigurationData.debugDictionary
            ]
        }
    }
}
