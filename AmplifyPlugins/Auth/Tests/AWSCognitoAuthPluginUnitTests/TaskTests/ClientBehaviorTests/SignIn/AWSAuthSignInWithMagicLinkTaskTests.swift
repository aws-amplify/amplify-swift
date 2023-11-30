//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0

import XCTest
import AWSCognitoIdentity
@testable import Amplify
@testable import AWSCognitoAuthPlugin
import AWSCognitoIdentityProvider
import ClientRuntime

class AWSAuthSignInWithMagicLinkTaskTests: BasePluginTest {

    override var initialState: AuthState {
        AuthState.configured(.signedOut(.init(lastKnownUserName: nil)), .configured)
    }

    /// Test happy path for signInWithMagicLink
    ///
    /// - Given: An auth plugin with mocked service.
    ///
    /// - When:
    ///    - I invoke signInWithMagicLink
    /// - Then:
    ///    - I should get the info in next step
    ///
    func testSignInWithMagicLink() async {
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
            XCTAssertEqual(input.clientMetadata?["Amplify.Passwordless.signInMethod"], "MAGIC_LINK")
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
        let options = AuthSignInWithMagicLinkRequest.Options(pluginOptions: pluginOptions)
        do {
            let result = try await plugin.signInWithMagicLink(
                username: "username",
                flow: .signIn,
                redirectURL: "https://example.com/magic-link/##code##",
                options: options)
            
            XCTAssertEqual((self.mockAuthPasswordlessBehavior as! MockAuthPasswordlessBehavior).preInitiateAuthSignUpCallCount, 0)
            
            guard case .confirmSignInWithMagicLink(let codeDeliveryDetails, _) = result.nextStep else {
                XCTFail("Result should be .confirmSignInWithMagicLink for next step")
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

    /// Test happy path for signInAndSignUpWithMagicLink
    ///
    /// - Given: An auth plugin with mocked service.
    ///
    /// - When:
    ///    - I invoke signInWithMagicLink with flow as `.signUpAndSignIn`
    /// - Then:
    ///    - I should get the correct info in next step
    ///
    func testSignUpAndSignInWithMagicLink() async {
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
            XCTAssertEqual(input.clientMetadata?["Amplify.Passwordless.signInMethod"], "MAGIC_LINK")
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
        let options = AuthSignInWithMagicLinkRequest.Options(pluginOptions: pluginOptions)
        do {
            let result = try await plugin.signInWithMagicLink(
                username: "username",
                flow: .signUpAndSignIn,
                redirectURL: "https://example.com/magic-link/##code##",
                options: options)
            
            XCTAssertEqual((self.mockAuthPasswordlessBehavior as! MockAuthPasswordlessBehavior).preInitiateAuthSignUpCallCount, 1)
            
            guard case .confirmSignInWithMagicLink(let codeDeliveryDetails, _) = result.nextStep else {
                XCTFail("Result should be .confirmSignInWithMagicLink for next step")
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
