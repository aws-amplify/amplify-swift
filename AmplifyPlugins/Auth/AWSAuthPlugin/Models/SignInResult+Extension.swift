//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import AWSMobileClient

extension SignInResult {

    func toAmplifyAuthSignInStep() throws -> AuthSignInStep {
        switch signInState {
        case .smsMFA:
            let deliveryDetails = AuthCodeDeliveryDetails(destination: .sms(codeDetails?.destination))
            return .confirmSignInWithSMSMFACode(deliveryDetails, nil)
        case .customChallenge:
            return .confirmSignInWithCustomChallenge(nil)
        case .newPasswordRequired:
            return .confirmSignInWithNewPassword(nil)
        default:
            throw (AmplifyAuthError.unknown("AWSMobileClient auth state is not handled"))
        }
    }
}
