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

                guard case .signUp(let request, let result) = cognitoAPI else {
                    fatalError("Missing input")
                }
                if let request = request {
                    XCTAssertEqual(input.clientId, request.clientId)
                    XCTAssertEqual(input.username, request.username)
                    XCTAssertEqual(input.password, request.password)
                }

                switch result {
                case .success(let response):
                    return response
                case .failure(let error):
                    throw error
                }
            },
            mockRevokeTokenResponse: { input in
                return RevokeTokenOutputResponse()
            },
            mockGlobalSignOutResponse: { input in
                return GlobalSignOutOutputResponse()
            },
            mockRespondToAuthChallengeResponse: { input in
                guard case .confirmSignIn(let request, let result) = cognitoAPI else {
                    fatalError("Missing input")
                }
                if let request = request {
                    XCTAssertEqual(request, input)
                }

                switch result {
                case .success(let response):
                    return response
                case .failure(let error):
                    throw error
                }
            },
            mockChangePasswordOutputResponse: { input in
                fatalError()
                //                    XCTAssertEqual(input, self.featureSpecification.cognitoService.changePassword.input)
                //                    return self.featureSpecification.cognitoService.changePassword.response
            },
            mockDeleteUserOutputResponse: { input in
                guard case .deleteUser(_, let result) = cognitoAPI else {
                    fatalError("Missing input")
                }
                switch result {
                case .success(let response):
                    return response
                case .failure(let error):
                    throw error
                }
            },
            mockForgotPasswordOutputResponse: { input in
                guard case .forgotPassword(let request, let result) = cognitoAPI else {
                    fatalError("Missing input")
                }
                if let request = request {
                    XCTAssertEqual(input.clientMetadata, request.clientMetadata)
                    XCTAssertEqual(input.clientId, request.clientId)
                    XCTAssertEqual(input.username, request.username)
                }

                switch result {
                case .success(let response):
                    return response
                case .failure(let error):
                    throw error
                }
            }

        )
    }


}
