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
            return .smsMFAChallenge
        case .customChallenge:
            return .customChallenge
        case .newPasswordRequired:
            return .newPasswordRequiredChallenge
        default:
            throw (AmplifyAuthError.unknown("AWSMobileClient auth state is not handled"))
        }
    }
}
