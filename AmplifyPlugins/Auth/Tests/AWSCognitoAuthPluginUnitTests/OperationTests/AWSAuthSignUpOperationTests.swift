//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
@testable import Amplify
@testable import AWSCognitoAuthPlugin
@testable import AWSPluginsTestCommon
import ClientRuntime

import AWSCognitoIdentityProvider

class AWSAuthSignUpOperationTests: XCTestCase {

    var queue: OperationQueue?

    let initialState = AuthState.configured(.signedOut(.init(lastKnownUserName: nil)), .configured)

    override func setUp() {
        super.setUp()
        queue = OperationQueue()
        queue?.maxConcurrentOperationCount = 1
    }
    override func tearDown() {
        super.tearDown()
        Amplify.reset()
        sleep(2)
    }

    func testSignUpOperationSuccess() throws {
        let exp = expectation(description: #function)
        let functionExpectation = expectation(description: "API call should be invoked")

        let signUp: MockIdentityProvider.MockSignUpResponse = { _ in
            functionExpectation.fulfill()
            return .init(codeDeliveryDetails: nil, userConfirmed: true, userSub: UUID().uuidString)
        }

        let request = AuthSignUpRequest(username: "jeffb",
                                        password: "Valid&99",
                                        options: AuthSignUpRequest.Options())

        let statemachine = Defaults.makeDefaultAuthStateMachine(
            initialState: initialState,
            userPoolFactory: {MockIdentityProvider(mockSignUpResponse: signUp)})
        let operation = AWSAuthSignUpOperation(request, stateMachine: statemachine) {  result in
            switch result {
            case .success(let signUpResult):
                print("Sign Up Result: \(signUpResult)")
            case .failure(let error):
                XCTAssertNil(error, "Error should not be returned")
            }
            exp.fulfill()
        }
        queue?.addOperation(operation)
        wait(for: [exp, functionExpectation], timeout: 1)

    }

    /// Given: Configured AuthState machine
    /// When: A new SignUp operation is added to the queue and mock a service failure
    /// Then: Should complete the signUp flow with an error
    ///
    func testSignUpOperationFailure() throws {
        let exp = expectation(description: #function)
        let functionExpectation = expectation(description: "API call should be invoked")
        let signUp: MockIdentityProvider.MockSignUpResponse = { _ in
            functionExpectation.fulfill()
            throw try SignUpOutputError(httpResponse: MockHttpResponse.ok)
        }

        let request = AuthSignUpRequest(username: "jeffb",
                                        password: "Valid&99",
                                        options: AuthSignUpRequest.Options())

        let statemachine = Defaults.makeDefaultAuthStateMachine(
            initialState: initialState,
            userPoolFactory: {MockIdentityProvider(mockSignUpResponse: signUp)})
        let operation = AWSAuthSignUpOperation(request, stateMachine: statemachine) {  result in
            switch result {
            case .success:
                XCTFail("Should not produce success response")
            case .failure(let error):
                print(error)
            }
            exp.fulfill()
        }
        queue?.addOperation(operation)
        wait(for: [exp, functionExpectation], timeout: 1)
    }

    /// Given: Configured AuthState machine with existing signUp flow
    /// When: A new SignUp operation is added to the queue
    /// Then: Should cancel the existing signUp flow and start a new flow and complete
    ///
    func testCancelExistingSignUp() throws {
        Amplify.Logging.logLevel = .verbose
        let exp = expectation(description: #function)
        let functionExpectation = expectation(description: "API call should be invoked")
        let signUp: MockIdentityProvider.MockSignUpResponse = { _ in
            functionExpectation.fulfill()
            return .init(codeDeliveryDetails: nil, userConfirmed: true, userSub: UUID().uuidString)
        }

        let request = AuthSignUpRequest(username: "jeffb",
                                        password: "Valid&99",
                                        options: AuthSignUpRequest.Options())

        let initialState = AuthState.configured(.signingUp(.notStarted), .configured)
        let statemachine = Defaults.makeDefaultAuthStateMachine(
            initialState: initialState,
            userPoolFactory: {MockIdentityProvider(mockSignUpResponse: signUp)})
        let operation = AWSAuthSignUpOperation(request, stateMachine: statemachine) {  result in
            switch result {
            case .success(let signUpResult):
                print("Sign Up Result: \(signUpResult)")
            case .failure(let error):
                XCTAssertNil(error, "Error should not be returned")
            }
            exp.fulfill()
        }
        queue?.addOperation(operation)
        wait(for: [exp, functionExpectation], timeout: 1)
    }
}
