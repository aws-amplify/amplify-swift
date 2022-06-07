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

import XCTest
@testable import Amplify
@testable import AWSCognitoAuthPlugin
@testable import AWSPluginsTestCommon
import ClientRuntime

import AWSCognitoIdentityProvider

class AWSAuthConfirmSignUpOperationTests: XCTestCase {

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

    func testConfirmSignUpOperationSuccess() throws {
        let exp = expectation(description: #function)
        let functionExpectation = expectation(description: "API call should be invoked")

        let confirmSignUp: MockIdentityProvider.MockConfirmSignUpResponse = { _ in
            functionExpectation.fulfill()
            return try .init(httpResponse: MockHttpResponse.ok)
        }

        let statemachine = Defaults.makeDefaultAuthStateMachine(
            initialState: initialState,
            userPoolFactory: {MockIdentityProvider(mockConfirmSignUpResponse: confirmSignUp)})

        let request = AuthConfirmSignUpRequest(username: "jeffb",
                                               code: "213",
                                               options: AuthConfirmSignUpRequest.Options())
        let operation = AWSAuthConfirmSignUpOperation(request,
                                                      stateMachine: statemachine) {result in
            switch result {
            case .success(let confirmSignUpResult):
                print("Confirm Sign Up Result: \(confirmSignUpResult)")
            case .failure(let error):
                XCTAssertNil(error, "Error should not be returned")
            }
            exp.fulfill()
        }
        queue?.addOperation(operation)

        wait(for: [exp, functionExpectation], timeout: 1)
    }

    func testConfirmSignUpOperationFailure() throws {
        let exp = expectation(description: #function)
        let functionExpectation = expectation(description: "API call should be invoked")

        let confirmSignUp: MockIdentityProvider.MockConfirmSignUpResponse = { _ in
            functionExpectation.fulfill()
            throw try ConfirmSignUpOutputError(httpResponse: MockHttpResponse.ok)
        }

        let statemachine = Defaults.makeDefaultAuthStateMachine(
            initialState: initialState,
            userPoolFactory: {MockIdentityProvider(mockConfirmSignUpResponse: confirmSignUp)})

        let request = AuthConfirmSignUpRequest(username: "jeffb",
                                               code: "213",
                                               options: AuthConfirmSignUpRequest.Options())

        let operation = AWSAuthConfirmSignUpOperation(request,
                                                      stateMachine: statemachine) {result in
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
}
