//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import AWSMobileClient

extension SignInState {

    func toAmplifyAuthSignInStep() throws -> AuthSignInStep {
        switch self {
        case .smsMFA:
            return .confirmSignInWithSMSMFACode
        case .customChallenge:
            return .confirmSignInWithCustomChallenge
        case .newPasswordRequired:
            return .confirmSignInWithNewPassword
        default:
            throw (AmplifyAuthError.unknown("AWSMobileClient auth state is not handled"))
        }
    }
}
