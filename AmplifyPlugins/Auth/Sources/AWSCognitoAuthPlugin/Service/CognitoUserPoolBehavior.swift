//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AWSCognitoIdentityProvider
import ClientRuntime

protocol CognitoUserPoolBehavior {

    func initiateAuth(input: InitiateAuthInput,
                      completion: @escaping (Result<InitiateAuthOutputResponse,
                                             SdkError<InitiateAuthOutputError>>) -> Void)

    func respondToAuthChallenge(input: RespondToAuthChallengeInput,
                                completion: @escaping (Result<RespondToAuthChallengeOutputResponse,
                                                       SdkError<RespondToAuthChallengeOutputError>>) -> Void)

    func signUp(input: SignUpInput, completion: @escaping (SdkResult<SignUpOutputResponse, SignUpOutputError>) -> Void)

    func confirmSignUp(input: ConfirmSignUpInput, completion: @escaping (SdkResult<ConfirmSignUpOutputResponse, ConfirmSignUpOutputError>) -> Void)

    func globalSignOut(
        input: GlobalSignOutInput,
        completion: @escaping (SdkResult<GlobalSignOutOutputResponse, GlobalSignOutOutputError>) -> Void
    )

    func revokeToken(
        input: RevokeTokenInput,
        completion: @escaping (SdkResult<RevokeTokenOutputResponse, RevokeTokenOutputError>) -> Void
    )
}
