//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
#if COCOAPODS
import AWSMobileClient
#else
import AWSMobileClientXCF
#endif

extension SignInResult {

    func toAmplifyAuthSignInStep() throws -> AuthSignInStep {
        switch signInState {
        case .signedIn:
            return .done
        case .smsMFA:
            let deliveryDetails = AuthCodeDeliveryDetails(destination: .sms(codeDetails?.destination))
            return .confirmSignInWithSMSMFACode(deliveryDetails, parameters)
        case .customChallenge:
            return .confirmSignInWithCustomChallenge(parameters)
        case .newPasswordRequired:
            return .confirmSignInWithNewPassword(parameters)
        default:
            throw (AuthError.unknown("AWSMobileClient auth state is not handled"))
        }
    }
}
