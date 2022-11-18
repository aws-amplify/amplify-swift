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
                    XCTAssertEqual(input, request)
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
                    XCTAssertEqual(input, request)
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
                    XCTAssertEqual(input, request)
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
                    XCTAssertEqual(request, input)
                }

                switch apiData.output {
                case .success(let response):
                    return response
                case .failure(let error):
                    throw error
                }
            }, mockChangePasswordOutputResponse: { input in
                fatalError()
                //                    XCTAssertEqual(input, self.featureSpecification.cognitoService.changePassword.input)
                //                    return self.featureSpecification.cognitoService.changePassword.response
            }, mockDeleteUserOutputResponse: { input in
                guard case .deleteUser(let apiData) = cognitoAPI[.deleteUser] else {
                    fatalError("Missing input")
                }
                switch apiData.output {
                case .success(let response):
                    return response
                case .failure(let error):
                    throw error
                }
            }, mockForgotPasswordOutputResponse: { input in
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
                    XCTAssertEqual(request, input)
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
