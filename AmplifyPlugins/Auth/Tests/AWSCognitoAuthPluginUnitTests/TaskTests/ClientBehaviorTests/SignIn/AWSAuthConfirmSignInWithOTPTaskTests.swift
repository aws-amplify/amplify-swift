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
                XCTAssertEqual(request.clientMetadata?["Amplify.Passwordless.signInMethod"], "OTP")
                XCTAssertEqual(request.clientMetadata?["Amplify.Passwordless.action"], "CONFIRM")
                XCTAssertEqual(request.clientMetadata?["somekey"], "somevalue")
                return .testData()
            })

        do {
            let confirmSignInOptions = AWSAuthConfirmSignInPasswordlessOptions(
                metadata: customerMetadata)
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

    /// Test a  confirmSignInWithOTP call when sending an invalid code
    ///
    /// - Given: an auth plugin with mocked service. Mocked service calls should throw an exception
    /// - When:
    ///    - I invoke confirmSignInWithOTP with an invalid confirmation code
    /// - Then:
    ///    - I should get a codeMismatch service exception
    ///
    func testConfirmSignInWithOTP() async {

        let customerMetadata = [
            "somekey": "somevalue"
        ]
        self.mockIdentityProvider = MockIdentityProvider(
            mockRespondToAuthChallengeResponse: { request in
                XCTAssertEqual(request.challengeName, .customChallenge)
                XCTAssertEqual(request.challengeResponses?["ANSWER"], "code")
                XCTAssertEqual(request.clientMetadata?["Amplify.Passwordless.signInMethod"], "OTP")
                XCTAssertEqual(request.clientMetadata?["Amplify.Passwordless.action"], "CONFIRM")
                XCTAssertEqual(request.clientMetadata?["somekey"], "somevalue")

                return RespondToAuthChallengeOutput(
                    authenticationResult: .none,
                    challengeName: .customChallenge,
                    challengeParameters: [
                        "nextStep": "PROVIDE_CHALLENGE_RESPONSE",
                        "errorCode": "CodeMismatchException"
                    ],
                    session: "session")
            })

        do {
            let confirmSignInOptions = AWSAuthConfirmSignInPasswordlessOptions(
                metadata: customerMetadata)
            let option = AuthConfirmSignInWithOTPRequest.Options(pluginOptions: confirmSignInOptions)
            _ = try await plugin.confirmSignInWithOTP(
                challengeResponse: "code",
                options: option)
            XCTFail("Confirm Sign In should not succeed")
        } catch AuthError.service(_, _, let error) {
            guard let cognitoError = error as? AWSCognitoAuthError else {
                XCTFail("Underlying error should be AWSCognitoAuthError instead got \(String(describing: error))")
                return
            }
            guard case .codeMismatch = cognitoError else {
                XCTFail("Underlying error should be .codeMismatch")
                return
            }
        } catch {
            XCTFail("Should throw a Auth.service error instead got \(error)")
        }
    }

}
