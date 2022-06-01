//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AWSCognitoIdentityProvider
import ClientRuntime

protocol CognitoUserPoolBehavior {

    /// Throws InitiateAuthOutputError
    func initiateAuth(input: InitiateAuthInput) async throws -> InitiateAuthOutputResponse

    /// Throws RespondToAuthChallengeOutputError
    func respondToAuthChallenge(
        input: RespondToAuthChallengeInput) async throws -> RespondToAuthChallengeOutputResponse

    /// Throws SignUpOutputError
    func signUp(input: SignUpInput) async throws -> SignUpOutputResponse

    /// Throws ConfirmSignUpOutputError
    func confirmSignUp(input: ConfirmSignUpInput) async throws -> ConfirmSignUpOutputResponse

    /// Throws GlobalSignOutOutputError
    func globalSignOut(input: GlobalSignOutInput) async throws -> GlobalSignOutOutputResponse

    /// Throws RevokeTokenOutputError
    func revokeToken(input: RevokeTokenInput) async throws -> RevokeTokenOutputResponse
}
