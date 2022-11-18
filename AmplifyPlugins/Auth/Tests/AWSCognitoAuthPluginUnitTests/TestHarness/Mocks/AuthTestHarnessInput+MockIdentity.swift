//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
import Foundation
import AWSCognitoIdentity

extension AuthTestHarnessInput {

    func getMockIdentity() -> MockIdentity {

        let getId: MockIdentity.MockGetIdResponse = { input in

            guard case .getId(let request, let result) = cognitoAPI[.getId] else {
                fatalError("Missing input")
            }
            if let request = request {
                XCTAssertEqual(request.logins, input.logins)
            }

            switch result {
            case .success(let response):
                return response
            case .failure(let error):
                throw error
            }
        }
        let getCredentials: MockIdentity.MockGetCredentialsResponse = { input in

            guard case .getCredentialsForIdentity(let request, let result) = cognitoAPI[.getCredentialsForIdentity] else {
                fatalError("Missing input")
            }
            if let request = request {
                XCTAssertEqual(request.logins, input.logins)
                XCTAssertEqual(request.identityId, input.identityId)
            }

            switch result {
            case .success(let response):
                return response
            case .failure(let error):
                throw error
            }
        }

        return MockIdentity(
            mockGetIdResponse: getId,
            mockGetCredentialsResponse: getCredentials)
    }

}
