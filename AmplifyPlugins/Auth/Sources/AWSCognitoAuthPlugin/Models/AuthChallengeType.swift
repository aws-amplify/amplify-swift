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

    case softwareTokenMfa

    case selectMFAType

    case setUpMFA

    case unknown(CognitoIdentityProviderClientTypes.ChallengeNameType)

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
        case .softwareTokenMfa:
            return .softwareTokenMfa
        case .selectMfaType:
            return .selectMFAType
        case .mfaSetup:
            return .setUpMFA
        default:
            return .unknown(self)
        }
    }
}

extension AuthChallengeType: Codable { }

extension AuthChallengeType: Equatable { }
