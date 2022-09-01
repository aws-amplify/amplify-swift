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

class AWSAuthSignUpTaskTests: XCTestCase {

    var queue: OperationQueue?

    let initialState = AuthState.configured(.signedOut(.init(lastKnownUserName: nil)), .configured)

    override func setUp() {
        super.setUp()
        queue = OperationQueue()
        queue?.maxConcurrentOperationCount = 1
    }

    func testSignUpOperationSuccess() async throws {
        let functionExpectation = expectation(description: "API call should be invoked")

        let signUp: MockIdentityProvider.MockSignUpResponse = { _ in
            functionExpectation.fulfill()
            return .init(codeDeliveryDetails: nil, userConfirmed: true, userSub: UUID().uuidString)
        }

        let request = AuthSignUpRequest(username: "jeffb",
                                        password: "Valid&99",
                                        options: AuthSignUpRequest.Options())
        let authEnvironment = Defaults.makeDefaultAuthEnvironment(
            userPoolFactory: {MockIdentityProvider(mockSignUpResponse: signUp)})
        let task = AWSAuthSignUpTask(request, authEnvironment: authEnvironment)
        let signUpResult = try await task.value
        print("Sign Up Result: \(signUpResult)")
        wait(for: [functionExpectation], timeout: 1)
    }

    /// Given: Configured AuthState machine
    /// When: A new SignUp operation is added to the queue and mock a service failure
    /// Then: Should complete the signUp flow with an error
    ///
    func testSignUpOperationFailure() async throws {
        let functionExpectation = expectation(description: "API call should be invoked")
        let signUp: MockIdentityProvider.MockSignUpResponse = { _ in
            functionExpectation.fulfill()
            throw try SignUpOutputError(httpResponse: MockHttpResponse.ok)
        }

        let request = AuthSignUpRequest(username: "jeffb",
                                        password: "Valid&99",
                                        options: AuthSignUpRequest.Options())

        let authEnvironment = Defaults.makeDefaultAuthEnvironment(
            userPoolFactory: {MockIdentityProvider(mockSignUpResponse: signUp)})
        let task = AWSAuthSignUpTask(request, authEnvironment: authEnvironment)
        do {
            _ = try await task.value
            XCTFail("Should not produce success response")
        } catch {
        }
        wait(for: [functionExpectation], timeout: 1)
    }

    /// Given: Configured AuthState machine with existing signUp flow
    /// When: A new SignUp operation is added to the queue
    /// Then: Should cancel the existing signUp flow and start a new flow and complete
    ///
    func testCancelExistingSignUp() async throws {
        Amplify.Logging.logLevel = .verbose
        let functionExpectation = expectation(description: "API call should be invoked")
        let signUp: MockIdentityProvider.MockSignUpResponse = { _ in
            functionExpectation.fulfill()
            return .init(codeDeliveryDetails: nil, userConfirmed: true, userSub: UUID().uuidString)
        }

        let request = AuthSignUpRequest(username: "jeffb",
                                        password: "Valid&99",
                                        options: AuthSignUpRequest.Options())

        let authEnvironment = Defaults.makeDefaultAuthEnvironment(
            userPoolFactory: {MockIdentityProvider(mockSignUpResponse: signUp)})
        let task = AWSAuthSignUpTask(request, authEnvironment: authEnvironment)
        let signUpResult = try await task.value
        wait(for: [functionExpectation], timeout: 1)
    }
}
