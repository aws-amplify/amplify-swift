//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

@testable import AWSCognitoAuthPlugin
import AWSCognitoIdentityProvider
import ClientRuntime

struct MockIdentityProvider: CognitoUserPoolBehavior {

    typealias InitiateAuthCallback = (InitiateAuthInput) throws
    -> InitiateAuthOutputResponse

    typealias RespondToAuthChallengeCallback = (RespondToAuthChallengeInput) throws
    -> RespondToAuthChallengeOutputResponse

    typealias SignUpCallback = (SignUpInput) throws -> SignUpOutputResponse

    typealias ConfirmSignUpCallback = (ConfirmSignUpInput) throws -> ConfirmSignUpOutputResponse

    typealias GlobalSignOutCallback = (GlobalSignOutInput) throws -> GlobalSignOutOutputResponse

    typealias RevokeTokenCallback = (RevokeTokenInput) throws -> RevokeTokenOutputResponse

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
        revokeTokenCallback: RevokeTokenCallback? = nil,
        newInitiate:  ((InitiateAuthInput) throws -> InitiateAuthOutputResponse)? = nil
    ) {
        self.initiateAuthCallback = initiateAuthCallback
        self.respondToAuthChallengeCallback = respondToAuthChallengeCallback
        self.signUpCallback = signUpCallback
        self.confirmSignUpCallback = confirmSignUpCallback
        self.globalSignOutCallback = globalSignOutCallback
        self.revokeTokenCallback = revokeTokenCallback
    }


    /// Throws InitiateAuthOutputError
    func initiateAuth(input: InitiateAuthInput) async throws -> InitiateAuthOutputResponse {
        return try initiateAuthCallback!(input)
    }

    /// Throws RespondToAuthChallengeOutputError
    func respondToAuthChallenge(
        input: RespondToAuthChallengeInput
    ) async throws -> RespondToAuthChallengeOutputResponse {
        return try respondToAuthChallengeCallback!(input)
    }

    /// Throws SignUpOutputError
    func signUp(input: SignUpInput) async throws -> SignUpOutputResponse {
        return try signUpCallback!(input)
    }

    /// Throws ConfirmSignUpOutputError
    func confirmSignUp(input: ConfirmSignUpInput) async throws -> ConfirmSignUpOutputResponse {
        return try confirmSignUpCallback!(input)
    }

    /// Throws GlobalSignOutOutputError
    func globalSignOut(input: GlobalSignOutInput) async throws -> GlobalSignOutOutputResponse {
        return try globalSignOutCallback!(input)
    }

    /// Throws RevokeTokenOutputError
    func revokeToken(input: RevokeTokenInput) async throws -> RevokeTokenOutputResponse {
        return try revokeTokenCallback!(input)
    }
}
