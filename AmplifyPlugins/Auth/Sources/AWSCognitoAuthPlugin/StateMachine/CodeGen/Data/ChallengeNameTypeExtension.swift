//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import AWSCognitoIdentityProvider

extension CognitoIdentityProviderClientTypes.ChallengeNameType {
    var authFactor: AuthFactorType? {
        switch self {
        case .emailOtp:
            return .emailOTP
        case .password:
            return .password
        case .passwordSrp:
            return .passwordSRP
        case .smsOtp:
            return .smsOTP
        case .webAuthn:
        #if os(iOS) || os(macOS) || os(visionOS)
            if #available(iOS 17.4, macOS 13.5, *) {
                return .webAuthn
            }
        #endif
            fallthrough
        default:
            // everything else is not supported as an auth factor
            return nil
        }
    }
}
