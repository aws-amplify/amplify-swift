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
@_spi(UnknownAWSHTTPServiceError) import AWSClientRuntime
import AWSCognitoIdentityProvider

class AWSAuthConfirmSignUpTaskTests: BasePluginTest {

    let signUpData = SignUpEventData(username: "jeffb")
    let signUpResult = AuthSignUpResult(.confirmUser())
    
    override var initialState: AuthState {
        AuthState.configured(
            .signedOut(.init(lastKnownUserName: nil)),
            .configured, 
            .awaitingUserConfirmation(signUpData, signUpResult))
    }

    func testConfirmSignUpOperationSuccess() async throws {
        self.mockIdentityProvider = MockIdentityProvider(
            mockConfirmSignUpResponse: { _ in
                return .init()
            }
        )
        
        let confirmSignUpResult = try await plugin.confirmSignUp(for: "jeffb",
                                                                 confirmationCode: "213", 
                                                                 options: AuthConfirmSignUpRequest.Options())
        XCTAssertTrue(confirmSignUpResult.isSignUpComplete)
        guard case .done = confirmSignUpResult.nextStep else {
            XCTFail("Next step should be done")
            return
        }
    }

    func testConfirmSignUpOperationFailure() async throws {
        self.mockIdentityProvider = MockIdentityProvider(
            mockConfirmSignUpResponse: { _ in
                throw AWSClientRuntime.UnknownAWSHTTPServiceError(
                    httpResponse: MockHttpResponse.ok,
                    message: nil,
                    requestID: nil,
                    typeName: nil
                )
            }
        )
        
        do {
            let _ = try await plugin.confirmSignUp(for: "jeffb",
                                                   confirmationCode: "213",
                                                   options: AuthConfirmSignUpRequest.Options())
            XCTFail("Should result in failure")
        } catch(let error) {
            XCTAssertNotNil(error)
        }
    }
}
