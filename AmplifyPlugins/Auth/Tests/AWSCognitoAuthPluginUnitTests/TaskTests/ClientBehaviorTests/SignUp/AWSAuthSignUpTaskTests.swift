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
@_spi(UnknownAWSHTTPServiceError) import AWSClientRuntime

import AWSCognitoIdentityProvider

class AWSAuthSignUpTaskTests: BasePluginTest {

    override var initialState: AuthState {
        AuthState.configured(.signedOut(.init(lastKnownUserName: nil)), .configured, .notStarted)
    }

    /// Given: Configured AuthState machine
    /// When: A new SignUp operation is added to the queue and mock a success failure
    /// Then: Should complete the signUp flow
    ///
    func testSignUpOperationSuccess() async throws {
        self.mockIdentityProvider = MockIdentityProvider(
            mockSignUpResponse: { _ in
                return .init(codeDeliveryDetails: nil, 
                             userConfirmed: true,
                             userSub: UUID().uuidString)
            }
        )
        let signUpResult = try await plugin.signUp(username: "jeffb",
                                                   password: "Valid&99",
                                                   options: AuthSignUpRequest.Options())
        XCTAssertTrue(signUpResult.isSignUpComplete)
        guard case .done = signUpResult.nextStep else {
            XCTFail("Next step should be done")
            return
        }
    }

    /// Given: Configured AuthState machine
    /// When: A new SignUp operation is added to the queue and mock a service failure
    /// Then: Should complete the signUp flow with an error
    ///
    func testSignUpOperationFailure() async throws {
        self.mockIdentityProvider = MockIdentityProvider(
            mockSignUpResponse: { _ in
                throw AWSClientRuntime.UnknownAWSHTTPServiceError(
                    httpResponse: MockHttpResponse.ok, message: nil, requestID: nil, typeName: nil
                )
            }
        )
        
        do {
            let _ = try await plugin.signUp(username: "jeffb",
                                                       password: "Valid&99",
                                                       options: AuthSignUpRequest.Options())
            XCTFail("Should result in failure")
        } catch (let error) {
            XCTAssertNotNil(error)
        }
    }
}
