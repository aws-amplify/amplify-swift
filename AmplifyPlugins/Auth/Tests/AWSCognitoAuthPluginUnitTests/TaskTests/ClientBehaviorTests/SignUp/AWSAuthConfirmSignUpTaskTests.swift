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




class AWSAuthConfirmSignUpTaskTests: XCTestCase {

    var queue: OperationQueue?

    override func setUp() {
        super.setUp()
        queue = OperationQueue()
        queue?.maxConcurrentOperationCount = 1
    }

    func testConfirmSignUpOperationSuccess() async throws {
        let functionExpectation = expectation(description: "API call should be invoked")
        let confirmSignUp: MockIdentityProvider.MockConfirmSignUpResponse = { _ in
            functionExpectation.fulfill()
            return .init()
        }

        let authEnvironment = Defaults.makeDefaultAuthEnvironment(
            userPoolFactory: {MockIdentityProvider(mockConfirmSignUpResponse: confirmSignUp)})

        let request = AuthConfirmSignUpRequest(username: "jeffb",
                                               code: "213",
                                               options: AuthConfirmSignUpRequest.Options())
        let task = AWSAuthConfirmSignUpTask(request, authEnvironment: authEnvironment)
        let confirmSignUpResult = try await task.value
        print("Confirm Sign Up Result: \(confirmSignUpResult)")
        await fulfillment(of: [functionExpectation], timeout: 1)
    }

    func testConfirmSignUpOperationFailure() async throws {
        let functionExpectation = expectation(description: "API call should be invoked")
        let confirmSignUp: MockIdentityProvider.MockConfirmSignUpResponse = { _ in
            functionExpectation.fulfill()
            throw PlaceholderError()
        }

        let authEnvironment = Defaults.makeDefaultAuthEnvironment(
            userPoolFactory: {MockIdentityProvider(mockConfirmSignUpResponse: confirmSignUp)})

        let request = AuthConfirmSignUpRequest(username: "jeffb",
                                               code: "213",
                                               options: AuthConfirmSignUpRequest.Options())

        do {
            let task = AWSAuthConfirmSignUpTask(request, authEnvironment: authEnvironment)
            _ = try await task.value
            XCTFail("Should not produce success response")
        } catch {
        }
        await fulfillment(of: [functionExpectation], timeout: 1)
    }
}
