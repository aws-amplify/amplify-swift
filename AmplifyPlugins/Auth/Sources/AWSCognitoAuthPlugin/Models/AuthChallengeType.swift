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

    case totpMFA

    case selectMFAType

    case setUpMFA

    case emailMFA

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
            return .totpMFA
        case .selectMfaType:
            return .selectMFAType
        case .mfaSetup:
            return .setUpMFA
        case .emailOtp:
            return .emailMFA
        default:
            return .unknown(self)
        }
    }
}

extension AuthChallengeType: Codable { }

extension AuthChallengeType: Equatable { }
