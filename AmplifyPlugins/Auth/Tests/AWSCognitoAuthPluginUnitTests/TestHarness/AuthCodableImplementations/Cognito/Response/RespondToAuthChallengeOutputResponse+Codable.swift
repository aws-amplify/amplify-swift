//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AWSCognitoIdentityProvider
import ClientRuntime

extension RespondToAuthChallengeOutputResponse: Codable {
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
        fatalError("This implementation is not needed")
    }
}
