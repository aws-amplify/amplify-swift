//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import AWSCognitoIdentityProvider

enum AuthChallengeType {

    case smsMfa

    case customChallenge

    case newPasswordRequired

    case unknown

}

extension CognitoIdentityProviderClientTypes.ChallengeNameType {
    var authChallengeType: AuthChallengeType {
        switch self {
        case .customChallenge:
            return .customChallenge
        case .newPasswordRequired:
            return .newPasswordRequired
        case .smsMfa:
            return .smsMfa
        default:
            return .unknown
        }
    }
}

extension AuthChallengeType: Codable { }
