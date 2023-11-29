//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0

import Foundation
import XCTest
import Amplify
@testable import AWSCognitoAuthPlugin
import AWSCognitoIdentityProvider

// swiftlint:disable type_body_length
// swiftlint:disable file_length
class AWSAuthConfirmSignInWithMagicLinkTaskTests: BasePluginTest {

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

    /// Test a successful confirmSignInWithMagicLink call with .done as next step
    ///
    /// - Given: an auth plugin with mocked service. Mocked service calls should mock a successful response
    /// - When:
    ///    - I invoke confirmSignInWithMagicLink with a valid code
    /// - Then:
    ///    - I should get a successful result with .done as the next step
    ///
    func testSuccessfulConfirmSignInWithMagicLink() async {

        let validMagicLinkToken = "eyJ1c2VybmFtZSI6InRlc3RAZXhhbXBsZS5jb20iLCJpYXQiOjE3MDExODkwODksImV4cCI6MTcwMTE4OTY4OX0.AQIDBAUGBwgJ"
        let customerMetadata = [
            "somekey": "somevalue"
        ]
        
        self.mockIdentityProvider = MockIdentityProvider(
            mockInitiateAuthResponse: { input in
                XCTAssertEqual(input.clientMetadata?["somekey"], "somevalue")
                XCTAssertEqual(input.authParameters?["USERNAME"], "test@example.com")

                return InitiateAuthOutput(
                    authenticationResult: .none,
                    challengeName: .customChallenge,
                    challengeParameters: [
                        "nextStep": "PROVIDE_AUTH_PARAMETERS"
                    ],
                    session: "someSession")
            },
            mockRespondToAuthChallengeResponse: { request in
                XCTAssertEqual(request.challengeName, .customChallenge)
                XCTAssertEqual(request.challengeResponses?["ANSWER"], validMagicLinkToken)
                XCTAssertEqual(request.clientMetadata?["Amplify.Passwordless.signInMethod"], "MAGIC_LINK")
                XCTAssertEqual(request.clientMetadata?["Amplify.Passwordless.action"], "CONFIRM")
                XCTAssertEqual(request.clientMetadata?["somekey"], "somevalue")
                return .testData()
            })

        do {
            let confirmSignInOptions = AWSAuthConfirmSignInWithMagicLinkOptions(
                metadata: customerMetadata)
            let option = AuthConfirmSignInWithMagicLinkRequest.Options(pluginOptions: confirmSignInOptions)
            let confirmSignInResult = try await plugin.confirmSignInWithMagicLink(
                challengeResponse: validMagicLinkToken,
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
