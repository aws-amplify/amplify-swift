//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AWSCognitoIdentityProvider
import Foundation
@testable import AWSCognitoAuthPlugin

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
            self = try .waitingForAnswer(
                RespondToAuthChallenge(
                    challenge: nestedContainerValue.decode(CognitoIdentityProviderClientTypes.ChallengeNameType.self, forKey: .challengeName),
                    // TODO: Fix deocoding
                    availableChallenges: [],
                    username: nestedContainerValue.decode(String.self, forKey: .username),
                    session: nestedContainerValue.decode(String.self, forKey: .session),
                    parameters: nestedContainerValue.decode([String: String].self, forKey: .parameters)
                ),
                .apiBased(.userSRP), .confirmSignInWithTOTPCode
            )
        } else {
            fatalError("Decoding not supported")
        }
    }

    public func encode(to encoder: Encoder) throws {

    }
}
