//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import ClientRuntime
import XCTest
@testable import Amplify

class AuthSignOutTests: AWSAuthBaseTest {
    // Enable this to set the aws-sdk-swift log level during debugging.
    // This can only be called once per process.
    private static var setSDKLogLevelDebug = true
    
    override func setUp() {
        super.setUp()
        initializeAmplify()
        
        if Self.setSDKLogLevelDebug {
            SDKLoggingSystem.initialize(logLevel: .debug)
            Self.setSDKLogLevelDebug = false
        }
    }
    
    override func tearDown() {
        super.tearDown()
        Amplify.reset()
        sleep(2)
    }
    
    /// Test successful signOut with globalSignout enabled.
    ///
    /// - Given: A user signed in via Cognito user pool
    /// - When:
    ///    - I invoke Amplify.Auth.signOut
    /// - Then:
    ///    - I should get a completed signout flow.
    ///
    func testGlobalSignOut() {
        let signInExpectation = expectation(description: "SignIn operation should complete")
        let signinOperation = signIn(signInExpectation.fulfill)
        wait(for: [signInExpectation], timeout: networkTimeout)
        XCTAssertTrue(signinOperation.isFinished, "SignIn operation should be finished.")
        
        print("calling signOut...")
        let signOutExpectation = expectation(description: "SignOut operation should complete")
        let signOutOperation = signOut(globalSignOut: true, completion: signOutExpectation.fulfill)
        wait(for: [signOutExpectation], timeout: networkTimeout)
        XCTAssertTrue(signOutOperation.isFinished, "SignOut operation should be finished.")
    }
    
    /// Test successful signOut with globalSignout disabled.
    ///
    /// - Given: A user signed in via Cognito user pool
    /// - When:
    ///    - I invoke Amplify.Auth.signOut
    /// - Then:
    ///    - I should get a completed signout flow.
    ///
    func testNonGlobalSignOut() {
        let signInExpectation = expectation(description: "SignIn operation should complete")
        let signinOperation = signIn(signInExpectation.fulfill)
        wait(for: [signInExpectation], timeout: networkTimeout)
        XCTAssertTrue(signinOperation.isFinished, "SignIn operation should be finished.")
        
        print("calling signOut...")
        let signOutExpectation = expectation(description: "SignOut operation should complete")
        let signOutOperation = signOut(globalSignOut: false, completion: signOutExpectation.fulfill)
        wait(for: [signOutExpectation], timeout: networkTimeout)
        XCTAssertTrue(signOutOperation.isFinished, "SignOut operation should be finished.")
    }
    
    /// Test if invoking signOut without unauthenticate state does not fail
    ///
    /// - Given: An unauthenticated state
    /// - When:
    ///    - I invoke signOut
    /// - Then:
    ///    - I should get a successul result
    ///
    func testSignedOutWithUnAuthState() {
        let operationExpectation = expectation(description: "Operation should complete")
        let operation = Amplify.Auth.signOut { result in
            defer {
                operationExpectation.fulfill()
            }
            switch result {
            case .success:
                print("Success signout")
            case .failure(let error):
                XCTFail("SignOut should not fail - \(error)")
            }
        }
        XCTAssertNotNil(operation, "SignOut operation should not be nil")
        wait(for: [operationExpectation], timeout: networkTimeout)
    }
        
    private func signIn(_ completion: @escaping ()->Void) -> AuthSignInOperation {
        let username = "xx"
        let password = "xx"
        
        let operation = Amplify.Auth.signIn(username: username, password: password) { result in
            defer {
                completion()
            }
            switch result {
            case .success(let signInResult):
                XCTAssertTrue(signInResult.isSignedIn, "SignIn should be complete")
            case .failure(let error):
                XCTFail("SignIn with a valid username/password should not fail \(error)")
            }
        }
        XCTAssertNotNil(operation, "SignIn operation should not be nil")
        return operation
    }
    
    private func signOut(globalSignOut: Bool, completion: @escaping ()->Void) -> AuthSignOutOperation {
        let options = AuthSignOutRequest.Options(globalSignOut: globalSignOut)
        
        let operation = Amplify.Auth.signOut(options: options) { result in
            defer {
                completion()
            }
            switch result {
            case .success:
                print("SignOut complete.")
            case .failure(let error):
                XCTFail("SignOut should not fail: \(error)")
            }
        }
        XCTAssertNotNil(operation, "SignOut operation should not be nil")
        return operation
    }
}

