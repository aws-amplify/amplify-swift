//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AWSCognitoIdentityProvider
import ClientRuntime

public protocol CognitoUserPoolBehavior {

    func initiateAuth(input: InitiateAuthInput,
                      completion: @escaping (Result<InitiateAuthOutputResponse,
                                             SdkError<InitiateAuthOutputError>>) -> Void)

    func respondToAuthChallenge(input: RespondToAuthChallengeInput,
                                completion: @escaping (Result<RespondToAuthChallengeOutputResponse,
                                                       SdkError<RespondToAuthChallengeOutputError>>) -> Void)

    func signUp(input: SignUpInput, completion: @escaping (ClientRuntime.SdkResult<SignUpOutputResponse, SignUpOutputError>) -> Void)

    func confirmSignUp(input: ConfirmSignUpInput, completion: @escaping (ClientRuntime.SdkResult<ConfirmSignUpOutputResponse, ConfirmSignUpOutputError>) -> Void)

}
