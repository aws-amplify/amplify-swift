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

            guard case .getId(let apiData) = cognitoAPI[.getId] else {
                fatalError("Missing input")
            }
            if let request = apiData.expectedInput {
                XCTAssertEqual(request.logins, input.logins)
            }

            switch apiData.output {
            case .success(let response):
                return response
            case .failure(let error):
                throw error
            }
        }
        let getCredentials: MockIdentity.MockGetCredentialsResponse = { input in

            guard case .getCredentialsForIdentity(let apiData) = cognitoAPI[.getCredentialsForIdentity] else {
                fatalError("Missing input")
            }
            if let request = apiData.expectedInput {
                XCTAssertEqual(request.logins, input.logins)
                XCTAssertEqual(request.identityId, input.identityId)
            }

            switch apiData.output {
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
