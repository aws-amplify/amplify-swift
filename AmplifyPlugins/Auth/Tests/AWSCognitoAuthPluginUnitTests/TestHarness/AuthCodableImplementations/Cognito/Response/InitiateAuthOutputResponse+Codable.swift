//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AWSCognitoIdentityProvider
import ClientRuntime

extension InitiateAuthOutput: Codable {

    enum CodingKeys: Swift.String, Swift.CodingKey {
        case authenticationResult = "AuthenticationResult"
        case challengeName = "ChallengeName"
        case challengeParameters = "ChallengeParameters"
        case session = "Session"
    }

    public init (from decoder: Swift.Decoder) throws {
        self.init()
        let containerValues = try decoder.container(keyedBy: CodingKeys.self)
        let challengeNameDecoded = try containerValues.decodeIfPresent(CognitoIdentityProviderClientTypes.ChallengeNameType.self, forKey: .challengeName)
        challengeName = challengeNameDecoded
        let sessionDecoded = try containerValues.decodeIfPresent(Swift.String.self, forKey: .session)
        session = sessionDecoded
        let challengeParametersContainer = try containerValues.decodeIfPresent([Swift.String: Swift.String?].self, forKey: .challengeParameters)
        var challengeParametersDecoded0: [Swift.String:Swift.String]? = nil
        if let challengeParametersContainer = challengeParametersContainer {
            challengeParametersDecoded0 = [Swift.String:Swift.String]()
            for (key0, stringtype0) in challengeParametersContainer {
                if let stringtype0 = stringtype0 {
                    challengeParametersDecoded0?[key0] = stringtype0
                }
            }
        }
        challengeParameters = challengeParametersDecoded0
        let authenticationResultDecoded = try containerValues.decodeIfPresent(CognitoIdentityProviderClientTypes.AuthenticationResultType.self, forKey: .authenticationResult)
        authenticationResult = authenticationResultDecoded
    }

    public func encode(to encoder: Encoder) throws {
        fatalError("Not supported")
    }

}

extension CognitoIdentityProviderClientTypes.AuthenticationResultType: Decodable {
    private enum CodingKeys: String, CodingKey {
        case accessToken = "AccessToken"
        case expiresIn = "ExpiresIn"
        case idToken = "IdToken"
        case newDeviceMetadata = "NewDeviceMetadata"
        case refreshToken = "RefreshToken"
        case tokenType = "TokenType"
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        try self.init(
            accessToken: container.decodeIfPresent(String.self, forKey: .accessToken),
            expiresIn: container.decode(Int.self, forKey: .expiresIn),
            idToken: container.decodeIfPresent(String.self, forKey: .idToken),
            newDeviceMetadata: container.decodeIfPresent(
                CognitoIdentityProviderClientTypes.NewDeviceMetadataType.self,
                forKey: .newDeviceMetadata
            ),
            refreshToken: container.decodeIfPresent(String.self, forKey: .refreshToken),
            tokenType: container.decodeIfPresent(String.self, forKey: .tokenType)
        )
    }
}

extension CognitoIdentityProviderClientTypes.NewDeviceMetadataType: Decodable {
    private enum CodingKeys: String, CodingKey {
        case deviceGroupKey = "DeviceGroupKey"
        case deviceKey = "DeviceKey"
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        try self.init(
            deviceGroupKey: container.decodeIfPresent(String.self, forKey: .deviceGroupKey),
            deviceKey: container.decodeIfPresent(String.self, forKey: .deviceKey)
        )
    }
}
