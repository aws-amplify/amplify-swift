//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AWSCognitoAuthPlugin
import AWSCognitoIdentityProvider
import ClientRuntime

struct MockIdentityProvider: CognitoUserPoolBehavior {

    typealias InitiateAuthCallback = (
        InitiateAuthInput,
        (Result<InitiateAuthOutputResponse,
         SdkError<InitiateAuthOutputError>>) -> Void
    ) -> Void

    typealias RespondToAuthChallengeCallback = (
        RespondToAuthChallengeInput,
        (Result<RespondToAuthChallengeOutputResponse,
         SdkError<RespondToAuthChallengeOutputError>>) -> Void
    ) -> Void

    typealias SignUpCallback = (
        SignUpInput,
        (Result<SignUpOutputResponse,
         SdkError<SignUpOutputError>>) -> Void
    ) -> Void

    typealias ConfirmSignUpCallback = (
        ConfirmSignUpInput,
        (Result<ConfirmSignUpOutputResponse,
         SdkError<ConfirmSignUpOutputError>>) -> Void
    ) -> Void
    
    typealias GlobalSignOutCallback = (
        GlobalSignOutInput,
        (Result<GlobalSignOutOutputResponse,
         SdkError<GlobalSignOutOutputError>>) -> Void
    ) -> Void
    
    typealias RevokeTokenCallback = (
        RevokeTokenInput,
        (Result<RevokeTokenOutputResponse,
         SdkError<RevokeTokenOutputError>>) -> Void
    ) -> Void

    let initiateAuthCallback: InitiateAuthCallback?
    let respondToAuthChallengeCallback: RespondToAuthChallengeCallback?
    let signUpCallback: SignUpCallback?
    let confirmSignUpCallback: ConfirmSignUpCallback?
    let globalSignOutCallback: GlobalSignOutCallback?
    let revokeTokenCallback: RevokeTokenCallback?

    init(
        initiateAuthCallback: InitiateAuthCallback? = nil,
        respondToAuthChallengeCallback: RespondToAuthChallengeCallback? = nil,
        signUpCallback: SignUpCallback? = nil,
        confirmSignUpCallback: ConfirmSignUpCallback? = nil,
        globalSignOutCallback: GlobalSignOutCallback? = nil,
        revokeTokenCallback: RevokeTokenCallback? = nil
    ) {
        self.initiateAuthCallback = initiateAuthCallback
        self.respondToAuthChallengeCallback = respondToAuthChallengeCallback
        self.signUpCallback = signUpCallback
        self.confirmSignUpCallback = confirmSignUpCallback
        self.globalSignOutCallback = globalSignOutCallback
        self.revokeTokenCallback = revokeTokenCallback
    }

    func initiateAuth(input: InitiateAuthInput,
                      completion: @escaping (Result<InitiateAuthOutputResponse,
                                             SdkError<InitiateAuthOutputError>>) -> Void)
    {
        initiateAuthCallback?(input, completion)
    }

    func respondToAuthChallenge(input: RespondToAuthChallengeInput,
                                completion: @escaping (Result<RespondToAuthChallengeOutputResponse,
                                                       SdkError<RespondToAuthChallengeOutputError>>) -> Void)
    {
        respondToAuthChallengeCallback?(input, completion)
    }

    func signUp(input: SignUpInput, completion: @escaping (SdkResult<SignUpOutputResponse, SignUpOutputError>) -> Void) {
        signUpCallback?(input, completion)
    }

    func confirmSignUp(input: ConfirmSignUpInput, completion: @escaping (SdkResult<ConfirmSignUpOutputResponse, ConfirmSignUpOutputError>) -> Void) {
        confirmSignUpCallback?(input, completion)
    }
    
    func globalSignOut(
        input: GlobalSignOutInput,
        completion: @escaping (SdkResult<GlobalSignOutOutputResponse, GlobalSignOutOutputError>) -> Void
    ) {
        globalSignOutCallback?(input, completion)
    }
    
    func revokeToken(
        input: RevokeTokenInput,
        completion: @escaping (ClientRuntime.SdkResult<RevokeTokenOutputResponse, RevokeTokenOutputError>) -> Void
    ) {
        revokeTokenCallback?(input, completion)
    }
}
