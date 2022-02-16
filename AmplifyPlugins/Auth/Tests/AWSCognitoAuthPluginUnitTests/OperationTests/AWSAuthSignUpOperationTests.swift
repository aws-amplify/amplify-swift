//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

//// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//
/* Commenting out the tests because of credential store not reachable in SPM
import XCTest
@testable import Amplify
@testable import AWSCognitoAuthPlugin
import ClientRuntime

import AWSCognitoIdentityProvider

 class AWSAuthSignUpOperationTests: XCTestCase {

    override func tearDown() {
        super.tearDown()
        Amplify.reset()
        sleep(2)
    }

    func testSignUpOperationSuccess() throws {
        let exp = expectation(description: #function)

        var called = false
        var testError: Error? = nil
        let userSub = UUID().uuidString
        let signUp: MockIdentityProvider.SignUpCallback = { _, completion in
            called = true
            completion(.success(.init(codeDeliveryDetails: nil, userConfirmed: true, userSub: userSub)))
        }

        let plugin = try createPlugin()

        let signUpEventData = SignUpEventData(username: "jeffb",
                                              password: "Valid&99",
                                              attributes: [:])

        IdentityProviderFactoryRegistry.shared[signUpEventData.key] = {
            MockIdentityProvider(signUpCallback: signUp)
        }
        defer {
            IdentityProviderFactoryRegistry.shared[signUpEventData.key] = nil
        }

        _ = plugin.signUp(username:signUpEventData.username, password: signUpEventData.password, options: nil) { result in
            switch result {
            case .success(let signUpResult):
                print("Sign Up Result: \(signUpResult)")
            case .failure(let error):
                testError = error
            }
            exp.fulfill()
        }

        wait(for: [exp], timeout: 2)

        XCTAssertTrue(called, "Signup closure should be called")
        XCTAssertNil(testError, "Error should not be returned")
    }

    func testSignUpOperationFailure() throws {
        let exp = expectation(description: #function)

        var called = false
        var testError: Error? = nil
        let signUp: MockIdentityProvider.SignUpCallback = { _, completion in
            called = true
            completion(.failure(.unknown(nil)))
        }

        let plugin = try createPlugin()

        let signUpEventData = SignUpEventData(username: "jeffb",
                                              password: "lowercase",
                                              attributes: [:])

        IdentityProviderFactoryRegistry.shared[signUpEventData.key] = {
            MockIdentityProvider(signUpCallback: signUp)
        }
        defer {
            IdentityProviderFactoryRegistry.shared[signUpEventData.key] = nil
        }

        _ = plugin.signUp(username:signUpEventData.username, password: signUpEventData.password, options: nil) { result in
            switch result {
            case .success:
                XCTFail("Operation should fail")
            case .failure(let error):
                testError = error
            }
            exp.fulfill()
        }

        wait(for: [exp], timeout: 2)

        XCTAssertTrue(called, "Signup closure should be called")
        XCTAssertNotNil(testError, "Error should be returned")
    }

    private func createPlugin(file: StaticString = #filePath,
                              line: UInt = #line) throws -> AWSCognitoAuthPlugin {
        let plugin = AWSCognitoAuthPlugin()
        try Amplify.add(plugin: plugin)

        let categoryConfig = AuthCategoryConfiguration(plugins: [
            "awsCognitoAuthPlugin": [
                "CredentialsProvider": ["CognitoIdentity": ["Default":
                                                                ["PoolId": "xx",
                                                                 "Region": "us-east-1"]
                                                           ]],
                "CognitoUserPool": ["Default": [
                    "PoolId": "xx",
                    "Region": "us-east-1",
                    "AppClientId": "xx",
                    "AppClientSecret": "xx"]]
            ]
        ])
        let amplifyConfig = AmplifyConfiguration(auth: categoryConfig)
        do {
            try Amplify.configure(amplifyConfig)
        } catch {
            XCTFail("Should not throw error. \(error)", file: file, line: line)
        }

        return plugin
    }
}
*/
