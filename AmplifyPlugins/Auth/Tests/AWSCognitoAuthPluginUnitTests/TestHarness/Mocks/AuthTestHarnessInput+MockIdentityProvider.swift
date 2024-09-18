//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
import AWSCognitoIdentityProvider

extension AuthTestHarnessInput {

    func getMockIdentityProvider() -> MockIdentityProvider {
        MockIdentityProvider(
            mockSignUpResponse: { input in

                guard case .signUp(let apiData) = cognitoAPI[.signUp] else {
                    fatalError("Missing input")
                }
                if let request = apiData.expectedInput {
                    XCTAssertEqual(input.clientId, request.clientId)
                    XCTAssertEqual(input.username, request.username)
                    XCTAssertEqual(input.password, request.password)
                }

                switch apiData.output {
                case .success(let response):
                    return response
                case .failure(let error):
                    throw error
                }
            }, mockRevokeTokenResponse: { input in
                guard case .revokeToken(let apiData) = cognitoAPI[.revokeToken] else {
                    fatalError("Missing input")
                }
                if let request = apiData.expectedInput {
                    XCTAssertEqual(input.clientId, request.clientId)
                    XCTAssertEqual(input.clientSecret, request.clientSecret)
                    XCTAssertEqual(input.token, request.token)
                }

                switch apiData.output {
                case .success(let response):
                    return response
                case .failure(let error):
                    throw error
                }
            }, mockInitiateAuthResponse: { input in
                guard case .initiateAuth(let apiData) = cognitoAPI[.initiateAuth] else {
                    fatalError("Missing input")
                }
                if let request = apiData.expectedInput {
                    XCTAssertEqual(input.clientId, request.clientId)
                    XCTAssertEqual(input.authParameters, request.authParameters)
                    XCTAssertEqual(input.clientMetadata, request.clientMetadata)
                }

                switch apiData.output {
                case .success(let response):
                    return response
                case .failure(let error):
                    throw error
                }
            },
            mockGlobalSignOutResponse: { input in
                guard case .globalSignOut(let apiData) = cognitoAPI[.globalSignOut] else {
                    fatalError("Missing input")
                }
                if let request = apiData.expectedInput {
                    XCTAssertEqual(input.accessToken, request.accessToken)
                }

                switch apiData.output {
                case .success(let response):
                    return response
                case .failure(let error):
                    throw error
                }
            },
            mockRespondToAuthChallengeResponse: { input in
                guard case .respondToAuthChallenge(let apiData) = cognitoAPI[.confirmSignIn] else {
                    fatalError("Missing input")
                }
                if let request = apiData.expectedInput {
                    XCTAssertEqual(request.challengeResponses, input.challengeResponses)
                    XCTAssertEqual(request.clientId, input.clientId)
                    XCTAssertEqual(request.clientMetadata, input.clientMetadata)
                    XCTAssertEqual(request.session, input.session)
                }

                switch apiData.output {
                case .success(let response):
                    return response
                case .failure(let error):
                    throw error
                }
            }, mockChangePasswordOutput: { input in
                fatalError()
                //                    XCTAssertEqual(input, self.featureSpecification.cognitoService.changePassword.input)
                //                    return self.featureSpecification.cognitoService.changePassword.response
            }, mockDeleteUserOutput: { input in
                guard case .deleteUser(let apiData) = cognitoAPI[.deleteUser] else {
                    fatalError("Missing input")
                }
                switch apiData.output {
                case .success(let response):
                    return response
                case .failure(let error):
                    throw error
                }
            }, mockForgotPasswordOutput: { input in
                guard case .forgotPassword(let apiData) = cognitoAPI[.forgotPassword] else {
                    fatalError("Missing input")
                }
                if let request = apiData.expectedInput {
                    XCTAssertEqual(input.clientMetadata, request.clientMetadata)
                    XCTAssertEqual(input.clientId, request.clientId)
                    XCTAssertEqual(input.username, request.username)
                }

                switch apiData.output {
                case .success(let response):
                    return response
                case .failure(let error):
                    throw error
                }
            }, mockConfirmDeviceResponse: { input in
                guard case .confirmDevice(let apiData) = cognitoAPI[.confirmDevice] else {
                    fatalError("Missing input")
                }
                if let request = apiData.expectedInput {
                    XCTAssertEqual(request.accessToken, input.accessToken)
                    XCTAssertEqual(request.deviceKey, input.deviceKey)
                    XCTAssertEqual(request.deviceName, input.deviceName)
                    XCTAssertEqual(request.deviceSecretVerifierConfig?.passwordVerifier, input.deviceSecretVerifierConfig?.passwordVerifier)
                }

                switch apiData.output {
                case .success(let response):
                    return response
                case .failure(let error):
                    throw error
                }
            }
        )
    }


}
