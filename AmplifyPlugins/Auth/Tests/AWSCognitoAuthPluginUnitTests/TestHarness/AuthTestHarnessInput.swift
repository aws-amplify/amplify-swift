//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AWSCognitoIdentity
import AWSCognitoIdentityProvider
import AWSPluginsCore
import ClientRuntime

@testable import Amplify
@testable import AWSCognitoAuthPlugin
import Foundation

struct AuthTestHarnessInput {
    let initialAuthState: AuthState
    let expectedAuthState: AuthState?
    let amplifyAPI: AmplifyAPI
    let cognitoAPI: [API.APIName: CognitoAPI]
}

extension AuthTestHarnessInput {

    static func createInput(
        from specification: FeatureSpecification
    ) async -> AuthTestHarnessInput {
        return await AuthTestHarnessInput(
            initialAuthState: specification.preConditions.initialAuthState,
            expectedAuthState: getExpectedAuthState(from: specification),
            amplifyAPI: getAmplifyAPIUnderTest(from: specification),
            cognitoAPI: getCognitoAPI(from: specification)
        )
    }

    private static func getAmplifyAPIUnderTest(from specification: FeatureSpecification) -> AmplifyAPI {
        return TestHarnessAPIDecoder.decode(
            specification: specification)
    }

    private static func getCognitoAPI(
        from specification: FeatureSpecification
    ) async-> [API.APIName: CognitoAPI] {
        return await CognitoAPIDecodingHelper.decode(with: specification)
    }

    private static func getExpectedAuthState(from specification: FeatureSpecification) -> AuthState? {
        guard let expectedAuthStateValidation = specification.validations.first(where: { validation in
            validation.value(at: "type") == .string("state")
        }) else {
            return nil
        }
        guard case .string(let expectedAuthStateFileName) = expectedAuthStateValidation.value(at: "expectedState") else {
            fatalError("State validation not found")
        }
        return AuthState.initialize(fileName: expectedAuthStateFileName)
    }
}

enum AmplifyAPI {
    case resetPassword(
        input: AuthResetPasswordRequest,
        expectedOutput: Result<AuthResetPasswordResult, AuthError>?)
    case signUp(
        input: AuthSignUpRequest,
        expectedOutput: Result<AuthSignUpResult, AuthError>?)
    case signIn(
        input: AuthSignInRequest,
        expectedOutput: Result<AuthSignInResult, AuthError>?)
    case fetchAuthSession(
        input: AuthFetchSessionRequest,
        expectedOutput: Result<AWSAuthCognitoSession, AuthError>?)
    case signOut(
        input: AuthSignOutRequest,
        expectedOutput: Result<AWSCognitoSignOutResult, AuthError>?)
    case deleteUser(
        input: Void,
        expectedOutput: Result<Void, AuthError>?)
    case confirmSignIn(
        input: AuthConfirmSignInRequest,
        expectedOutput: Result<AuthSignInResult, AuthError>?)
}

enum CognitoAPI {
    case forgotPassword(CognitoAPIData<ForgotPasswordInput, ForgotPasswordOutputResponse, ForgotPasswordOutputError>)
    case signUp(CognitoAPIData<SignUpInput, SignUpOutputResponse, SignUpOutputError>)
    case deleteUser(CognitoAPIData<DeleteUserInput, DeleteUserOutputResponse, DeleteUserOutputError>)
    case respondToAuthChallenge(CognitoAPIData<RespondToAuthChallengeInput, RespondToAuthChallengeOutputResponse, RespondToAuthChallengeOutputError>)
    case getId(CognitoAPIData<GetIdInput, GetIdOutputResponse, GetIdOutputError>)
    case getCredentialsForIdentity(CognitoAPIData<GetCredentialsForIdentityInput, GetCredentialsForIdentityOutputResponse, GetCredentialsForIdentityOutputError>)
    case confirmDevice(CognitoAPIData<ConfirmDeviceInput, ConfirmDeviceOutputResponse, ConfirmDeviceOutputError>)
    case initiateAuth(CognitoAPIData<InitiateAuthInput, InitiateAuthOutputResponse, InitiateAuthOutputError>)
    case revokeToken(CognitoAPIData<RevokeTokenInput, RevokeTokenOutputResponse, RevokeTokenOutputError>)
    case globalSignOut(CognitoAPIData<GlobalSignOutInput, GlobalSignOutOutputResponse, GlobalSignOutOutputError>)
}

struct CognitoAPIData<Input: Decodable, Output: Decodable, E: ClientRuntime.HttpResponseErrorBinding> {

    let expectedInput: Input?
    let errorBinding: E.Type
    let output: Result<Output, Error>

}
