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

    case passwordRequired

    case totpMFA

    case selectMFAType

    case setUpMFA

    case smsOTP

    case emailOTP

    case selectAuthFactor

    case unknown(CognitoIdentityProviderClientTypes.ChallengeNameType)

}

extension CognitoIdentityProviderClientTypes.ChallengeNameType: Codable {
    var authChallengeType: AuthChallengeType {
        switch self {
        case .customChallenge:
            return .customChallenge
        case .newPasswordRequired:
            return .newPasswordRequired
        case .password, .passwordSrp:
            return .passwordRequired
        case .smsMfa:
            return .smsMfa
        case .softwareTokenMfa:
            return .totpMFA
        case .selectMfaType:
            return .selectMFAType
        case .mfaSetup:
            return .setUpMFA
        case .emailOtp:
            return .emailOTP
        case .smsOtp:
            return .smsOTP
        case .selectChallenge:
            return .selectAuthFactor
        case .webAuthn:
            fatalError("implement me!")
        default:
            return .unknown(self)
        }
    }
}

extension AuthChallengeType: Codable { }

extension AuthChallengeType: Equatable { }
