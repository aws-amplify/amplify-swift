//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

import XCTest
import Amplify
@testable import AWSCognitoAuthPlugin
import AWSCognitoIdentityProvider

// swiftlint:disable type_body_length
// swiftlint:disable file_length
class AWSAuthConfirmSignInWithOTPTaskTests: BasePluginTest {

    override var initialState: AuthState {
        AuthState.configured(
            AuthenticationState.signingIn(
                .resolvingChallenge(
                    .waitingForAnswer(
                        .testData(
                            challenge: .customChallenge,
                            parameters: [
                                "nextStep": "PROVIDE_CHALLENGE_RESPONSE",
                                "attributeName": "email",
                                "deliveryMedium": "EMAIL",
                                "destination": "S***@g***"
                            ]),
                        .apiBased(.customWithoutSRP)
                    ),
                    .customChallenge,
                    .apiBased(.customWithoutSRP))),
            AuthorizationState.sessionEstablished(.testData))
    }

    /// Test a successful confirmSignInWithOTP call with .done as next step
    ///
    /// - Given: an auth plugin with mocked service. Mocked service calls should mock a successful response
    /// - When:
    ///    - I invoke confirmSignInWithOTP with a valid confirmation code
    /// - Then:
    ///    - I should get a successful result with .done as the next step
    ///
    func testSuccessfulConfirmSignInWithOTP() async {

        let customerMetadata = [
            "somekey": "somevalue"
        ]
        self.mockIdentityProvider = MockIdentityProvider(
            mockRespondToAuthChallengeResponse: { request in
                XCTAssertEqual(request.challengeName, .customChallenge)
                XCTAssertEqual(request.challengeResponses?["ANSWER"], "code")
                XCTAssertEqual(request.clientMetadata?["signInMethod"], "OTP")
                XCTAssertEqual(request.clientMetadata?["action"], "CONFIRM")
                XCTAssertEqual(request.clientMetadata?["somekey"], "somevalue")
                return .testData()
            })

        do {
            let confirmSignInOptions = AWSAuthConfirmSignInOptions(metadata: customerMetadata)
            let option = AuthConfirmSignInWithOTPRequest.Options(pluginOptions: confirmSignInOptions)
            let confirmSignInResult = try await plugin.confirmSignInWithOTP(
                challengeResponse: "code",
                options: option)

            guard case .done = confirmSignInResult.nextStep else {
                XCTFail("Result should be .done for next step")
                return
            }
            XCTAssertTrue(confirmSignInResult.isSignedIn, "Signin result should be complete")
        } catch {
            XCTFail("Received failure with error \(error)")
        }
    }

}
