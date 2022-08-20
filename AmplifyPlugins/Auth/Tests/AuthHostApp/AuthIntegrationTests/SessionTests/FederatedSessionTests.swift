//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
@testable import Amplify
import AWSCognitoAuthPlugin
import AWSPluginsCore

class FederatedSessionTests: AWSAuthBaseTest {

    override func setUp() {
        super.setUp()
        initializeAmplify()
        AuthSessionHelper.clearSession()
    }

    override func tearDown() async throws {
        try await super.tearDown()
        AuthSessionHelper.clearSession()
        await Amplify.reset()
    }

    /// Test unsuccessful federation
    ///
    /// - Given: A not authorized token from 3P provider
    /// - When:
    ///    - I invoke Amplify.Auth.federateToIdentityPool
    /// - Then:
    ///    - I should get a not authorized error
    ///
    func testUnsuccessfulFederation() {

        let operationExpectation = expectation(description: "Operation should complete")
        let authCognitoPlugin = try! Amplify.Auth.getPlugin(for: "awsCognitoAuthPlugin") as! AWSCognitoAuthPlugin
        let operation = authCognitoPlugin.federateToIdentityPool(
            withProviderToken: "someToken",
            for: .facebook) { result in
                defer {
                    operationExpectation.fulfill()
                }
                switch result {
                case .success:
                    XCTFail("Federation should not succeed")
                case .failure(let error):
                    guard case .notAuthorized = error else {
                        XCTFail("SignIn with a valid username/password should not fail \(error)")
                        return
                    }
                }
            }
        XCTAssertNotNil(operation, "SignIn operation should not be nil")
        wait(for: [operationExpectation], timeout: networkTimeout)
    }

}
