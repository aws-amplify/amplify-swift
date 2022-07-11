//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import AWSCognitoIdentityProvider

protocol SignInResponseBehavior {

    /// The result returned by the server in response to the request to respond to the authentication challenge.
    var authenticationResult: CognitoIdentityProviderClientTypes.AuthenticationResultType? { get }
    /// The challenge name.
    var challengeName: CognitoIdentityProviderClientTypes.ChallengeNameType? { get }
    /// The challenge parameters.
    var challengeParameters: [Swift.String:Swift.String]? { get }
    /// The session which should be passed both ways in challenge-response calls to the service. If the caller needs to go through another challenge, they return a session with other challenge parameters. This session should be passed as it is to the next RespondToAuthChallenge API call.
    var session: Swift.String? { get }
}

extension RespondToAuthChallengeOutputResponse: SignInResponseBehavior { }

extension InitiateAuthOutputResponse: SignInResponseBehavior { }
