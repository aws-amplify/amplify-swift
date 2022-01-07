//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import hierarchical_state_machine_swift

public enum AuthConfiguration {
    case userPools(UserPoolConfigurationData)
    case identityPools(IdentityPoolConfigurationData)
    case userPoolsAndIdentityPools(UserPoolConfigurationData, IdentityPoolConfigurationData)
}

extension AuthConfiguration: Equatable { }

extension AuthConfiguration: Codable {
    enum CodingKeys: CodingKey {
        case userPools
        case identityPools
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        switch self {
        case .userPools(let configData):
            try container.encode(configData, forKey: .userPools)
        case .identityPools(let configData):
            try container.encode(configData, forKey: .identityPools)
        case .userPoolsAndIdentityPools(let userPoolConfigData, let identityPoolConfigData):
            try container.encode(identityPoolConfigData, forKey: .identityPools)
            try container.encode(userPoolConfigData, forKey: .userPools)
        }
    }

    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)

        let userConfigData = try? values.decode(UserPoolConfigurationData.self, forKey: .userPools)
        let idpConfigData = try? values.decode(IdentityPoolConfigurationData.self, forKey: .identityPools)

        guard userConfigData != nil || idpConfigData != nil else {
            throw DecodingError.dataCorrupted(
                DecodingError.Context(codingPath: values.codingPath,
                                      debugDescription: "Unable to decode")
            )
        }

        if let userPoolData = userConfigData, let identityPoolData = idpConfigData {
            self = .userPoolsAndIdentityPools(userPoolData, identityPoolData)
        } else if let identityPoolData = idpConfigData {
            self = .identityPools(identityPoolData)
        } else {
            self = .userPools(userConfigData!)
        }

    }

}

extension AuthConfiguration {
    
    func getUserPoolConfiguration() -> UserPoolConfigurationData? {
        switch self {
        case .userPools(let userPoolConfigurationData),
                .userPoolsAndIdentityPools(let userPoolConfigurationData, _):
            return userPoolConfigurationData
        case .identityPools(_): return nil
        }
    }
    
    func getIdentityPoolConfiguration() -> IdentityPoolConfigurationData? {
        switch self {
        case .identityPools(let identityPoolConfigurationData),
                .userPoolsAndIdentityPools( _, let identityPoolConfigurationData):
            return identityPoolConfigurationData
        case .userPools(_): return nil
        }
    }
}

extension AuthConfiguration: CustomDebugDictionaryConvertible {
    public var debugDictionary: [String: Any] {
        switch self {
        case .userPools(let userPoolConfigurationData):
            return [
                "AuthenticationConfiguration": "userPools",
                "- UserPoolConfigurationData": userPoolConfigurationData.debugDictionary
            ]
        case .identityPools(let identityPoolConfigurationData):
            return [
                "AuthenticationConfiguration": "identityPools",
                "- IdentityPoolConfigurationData": identityPoolConfigurationData.debugDictionary
            ]
        case .userPoolsAndIdentityPools(let userPoolConfigurationData, let identityPoolConfigurationData):
            return [
                "AuthenticationConfiguration": "userPoolsAndIdentityPools",
                "- UserPoolConfigurationData": userPoolConfigurationData.debugDictionary,
                "- IdentityPoolConfigurationData": identityPoolConfigurationData.debugDictionary
            ]
        }
    }
}
