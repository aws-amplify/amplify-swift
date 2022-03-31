//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

import AWSCognitoIdentity
import AWSCognitoIdentityProvider
import AWSClientRuntime
import ClientRuntime

extension CognitoUserPoolBehavior {

    func initiateAuth(input: InitiateAuthInput,
                      completion: @escaping (Result<InitiateAuthOutputResponse,
                                             SdkError<InitiateAuthOutputError>>) -> Void) {
#warning("Not Implemented")
        fatalError("Not Implemented")
    }

    func respondToAuthChallenge(input: RespondToAuthChallengeInput,
                                completion: @escaping (Result<RespondToAuthChallengeOutputResponse,
                                                       SdkError<RespondToAuthChallengeOutputError>>) -> Void) {
#warning("Not Implemented")
        fatalError("Not Implemented")
    }

    func signUp(input: SignUpInput, completion: @escaping (SdkResult<SignUpOutputResponse, SignUpOutputError>) -> Void)

    func confirmSignUp(input: ConfirmSignUpInput, completion: @escaping (SdkResult<ConfirmSignUpOutputResponse, ConfirmSignUpOutputError>) -> Void) {
#warning("Not Implemented")
        fatalError("Not Implemented")
    }

    func globalSignOut(
        input: GlobalSignOutInput,
        completion: @escaping (SdkResult<GlobalSignOutOutputResponse, GlobalSignOutOutputError>) -> Void
    ) {
#warning("Not Implemented")
        fatalError("Not Implemented")
    }

    func revokeToken(
        input: RevokeTokenInput,
        completion: @escaping (SdkResult<RevokeTokenOutputResponse, RevokeTokenOutputError>) -> Void
    ) {
#warning("Not Implemented")
        fatalError("Not Implemented")
    }

}
