//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest

extension AuthTestHarnessInput {

    func getMockIdentityProvider() -> MockIdentityProvider {
        MockIdentityProvider(
            mockChangePasswordOutputResponse: { input in
                fatalError()
                //                    XCTAssertEqual(input, self.featureSpecification.cognitoService.changePassword.input)
                //                    return self.featureSpecification.cognitoService.changePassword.response
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
