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

    let initiateAuthCallback: InitiateAuthCallback?
    let respondToAuthChallengeCallback: RespondToAuthChallengeCallback?

    init(
        initiateAuthCallback: InitiateAuthCallback? = nil,
        respondToAuthChallengeCallback: RespondToAuthChallengeCallback? = nil
    ) {
        self.initiateAuthCallback = initiateAuthCallback
        self.respondToAuthChallengeCallback = respondToAuthChallengeCallback
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
}
