//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
import AWSCognitoIdentity
@testable import Amplify
@testable import AWSCognitoAuthPlugin
import AWSCognitoIdentityProvider
import ClientRuntime

class AWSAuthSignInWithOTPTaskTests: BasePluginTest {

    override var initialState: AuthState {
        AuthState.configured(.signedOut(.init(lastKnownUserName: nil)), .configured)
    }

    /// Test happy path for signInWithOTP
    ///
    /// - Given: An auth plugin with mocked service.
    ///
    /// - When:
    ///    - I invoke signInWithOTP
    /// - Then:
    ///    - I should get a the info in next step
    ///
    func testSignInWithOTP() async {

        let clientMetadata = [
            "somekey": "somevalue"
        ]
        self.mockIdentityProvider = MockIdentityProvider(mockInitiateAuthResponse: { input in
            XCTAssertEqual(input.clientMetadata?["somekey"], "somevalue")
            return InitiateAuthOutput(
                authenticationResult: .none,
                challengeName: .customChallenge,
                challengeParameters: [
                    "nextStep": "PROVIDE_AUTH_PARAMETERS"
                ],
                session: "someSession")
        }, mockRespondToAuthChallengeResponse: { input in
            XCTAssertEqual(input.clientMetadata?["Amplify.Passwordless.signInMethod"], "OTP")
            XCTAssertEqual(input.clientMetadata?["Amplify.Passwordless.action"], "REQUEST")
            XCTAssertEqual(input.clientMetadata?["Amplify.Passwordless.deliveryMedium"], "EMAIL")
            XCTAssertEqual(input.clientMetadata?["somekey"], "somevalue")

            return RespondToAuthChallengeOutput(
                authenticationResult: .none,
                challengeName: .customChallenge,
                challengeParameters: [
                    "nextStep": "PROVIDE_CHALLENGE_RESPONSE",
                    "attributeName": "email",
                    "deliveryMedium": "EMAIL",
                    "destination": "S***@g***"
                ],
                session: "session")
        })

        let pluginOptions = AWSAuthSignInPasswordlessOptions(clientMetadata: clientMetadata)
        let options = AuthSignInWithOTPRequest.Options(pluginOptions: pluginOptions)
        do {
            let result = try await plugin.signInWithOTP(
                username: "username",
                flow: .signIn,
                destination: .email,
                options: options)
            
            guard case .confirmSignInWithOTP(let codeDeliveryDetails, _) = result.nextStep else {
                XCTFail("Result should be .confirmSignInWithOTP for next step")
                return
            }

            guard case .email(let destination) = codeDeliveryDetails.destination else {
                XCTFail("Result should contain codeDeliveryDetails.destination")
                return
            }

            XCTAssertNotNil(destination, "Destination should not be nil")
            XCTAssertEqual(destination, "S***@g***")

            guard case .email = codeDeliveryDetails.attributeKey else {
                XCTFail("Result for codeDeliveryDetails.attributeKey should be email")
                return
            }

            XCTAssertFalse(result.isSignedIn, "Signin result should not be complete")
        } catch {
            XCTFail("Received failure with error \(error)")
        }
    }

}
