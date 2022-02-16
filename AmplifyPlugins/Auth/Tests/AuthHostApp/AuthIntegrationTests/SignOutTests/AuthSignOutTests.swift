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
        AuthSessionHelper.invalidateSessions()
        if Self.setSDKLogLevelDebug {
            SDKLoggingSystem.initialize(logLevel: .debug)
            Self.setSDKLogLevelDebug = false
        }
    }

    override func tearDown() {
        super.tearDown()
        Amplify.reset()
        AuthSessionHelper.invalidateSessions()
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
        let username = "integTest\(UUID().uuidString)"
        let password = "P123@\(UUID().uuidString)"

        let signUpExpectation = expectation(description: "SignUp operation should complete")
        AuthSignInHelper.registerAndSignInUser(username: username,
                                    password: password,
                                    email: defaultTestEmail) { didSucceed, error in
            signUpExpectation.fulfill()
            XCTAssertTrue(didSucceed, "Signup operation failed - \(String(describing: error))")
        }
        wait(for: [signUpExpectation], timeout: networkTimeout)
        
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
        let username = "integTest\(UUID().uuidString)"
        let password = "P123@\(UUID().uuidString)"

        let signUpExpectation = expectation(description: "SignUp operation should complete")
        AuthSignInHelper.registerAndSignInUser(username: username,
                                    password: password,
                                    email: defaultTestEmail) { didSucceed, error in
            signUpExpectation.fulfill()
            XCTAssertTrue(didSucceed, "Signup operation failed - \(String(describing: error))")
        }
        wait(for: [signUpExpectation], timeout: networkTimeout)
        
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

