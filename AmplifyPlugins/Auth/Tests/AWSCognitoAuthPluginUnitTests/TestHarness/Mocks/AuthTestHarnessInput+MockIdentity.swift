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
        let getId: MockIdentity.MockGetIdResponse = { _ in
            return .init(identityId: "mockIdentityId")
        }

        let getCredentials: MockIdentity.MockGetCredentialsResponse = { _ in
            let credentials = CognitoIdentityClientTypes.Credentials(
                accessKeyId: "accessKey",
                expiration: Date(),
                secretKey: "secret",
                sessionToken: "session")
            return .init(credentials: credentials, identityId: "responseIdentityID")
        }

        return MockIdentity(
            mockGetIdResponse: getId,
            mockGetCredentialsResponse: getCredentials)
    }

}
