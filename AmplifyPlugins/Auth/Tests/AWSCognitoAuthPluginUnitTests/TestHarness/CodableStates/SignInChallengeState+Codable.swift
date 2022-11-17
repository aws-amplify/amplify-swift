//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

@testable import AWSCognitoAuthPlugin
import AWSCognitoIdentityProvider
import Foundation

extension SignInChallengeState: Codable {
    enum CodingKeys: String, CodingKey {
        case type
        case authChallenge
        case challengeName
        case username
        case session
        case parameters
    }

    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        let nestedContainerValue = try values.nestedContainer(keyedBy: CodingKeys.self, forKey: .authChallenge)
        
        let type = try values.decode(String.self, forKey: .type)
        if type == "SignInChallengeState.WaitingForAnswer" {
            self = .waitingForAnswer(
                RespondToAuthChallenge(
                    challenge: try nestedContainerValue.decode(CognitoIdentityProviderClientTypes.ChallengeNameType.self, forKey: .challengeName),
                    username: try nestedContainerValue.decode(String.self, forKey: .username),
                    session: try nestedContainerValue.decode(String.self, forKey: .session),
                    parameters: try nestedContainerValue.decode([String: String].self, forKey: .parameters)),
                .apiBased(.userSRP))
        } else {
            fatalError("Decoding not supported")
        }
    }

    public func encode(to encoder: Encoder) throws {

    }
}
