//// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
@testable import Amplify
@testable import AWSCognitoAuthPlugin
import ClientRuntime

import AWSCognitoIdentityProvider

class AWSAuthConfirmSignUpOperationTests: XCTestCase {
    
    override func tearDown() {
        super.tearDown()
        Amplify.reset()
        sleep(2)
    }
    
    func testConfirmSignUpOperationSuccess() throws {
        let exp = expectation(description: #function)
        
        var called = false
        var testError: Error? = nil
        let confirmSignUp: MockIdentityProvider.ConfirmSignUpCallback = { _, completion in
            called = true
            completion(.success(.init()))
        }
        
        let plugin = try createPlugin()
        
        let confirmSignUpEventData = ConfirmSignUpEventData(username: "jeffb", confirmationCode: "07051994")
        
        IdentityProviderFactoryRegistry.shared[confirmSignUpEventData.key] = {
            MockIdentityProvider(confirmSignUpCallback: confirmSignUp)
        }
        defer {
            IdentityProviderFactoryRegistry.shared[confirmSignUpEventData.key] = nil
        }
        
        _ = plugin.confirmSignUp(for: confirmSignUpEventData.username, confirmationCode: confirmSignUpEventData.confirmationCode, options: nil) { result in
            switch result {
            case .success(let confirmSignUpResult):
                print("Confirm Sign Up Result: \(confirmSignUpResult)")
            case .failure(let error):
                testError = error
            }
            exp.fulfill()
        }
        
        wait(for: [exp], timeout: 300.0)
        
        XCTAssertTrue(called, "Confirm Signup closure should be called")
        XCTAssertNil(testError, "Error should not be returned")
    }
    
    func testConfirmSignUpOperationFailure() throws {
        let exp = expectation(description: #function)
        
        var called = false
        var testError: Error? = nil
        let confirmSignUp: MockIdentityProvider.ConfirmSignUpCallback = { _, completion in
            called = true
            completion(.failure(.unknown(nil)))
        }
        
        let plugin = try createPlugin()
        
        let confirmSignUpEventData = ConfirmSignUpEventData(username: "jeffb", confirmationCode: "07051994")
        
        IdentityProviderFactoryRegistry.shared[confirmSignUpEventData.key] = {
            MockIdentityProvider(confirmSignUpCallback: confirmSignUp)
        }
        defer {
            IdentityProviderFactoryRegistry.shared[confirmSignUpEventData.key] = nil
        }
        
        _ = plugin.confirmSignUp(for: confirmSignUpEventData.username, confirmationCode: confirmSignUpEventData.confirmationCode, options: nil) { result in
            switch result {
            case .success:
                XCTFail("Operation should fail")
            case .failure(let error):
                testError = error
            }
            exp.fulfill()
        }
        
        wait(for: [exp], timeout: 300.0)
        
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
