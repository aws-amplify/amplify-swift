//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AWSCognitoIdentityProvider
import XCTest
@testable import Amplify
@testable import AWSCognitoAuthPlugin
import InternalAWSCognitoAuth

/// The new user's sub on every `signUp` result that completes, auto sign-in included. `confirmSignUp`'s results carry
/// none: Cognito's `ConfirmSignUp` answer has no sub.
class AWSAuthSignUpUserIDTests: BasePluginTest, @unchecked Sendable {

    let options = AuthSignUpRequest.Options(userAttributes: [
        .init(.email, value: "random@random.com")
    ])

    override var initialState: AuthState {
        AuthState.configured(.signedOut(.init(lastKnownUserName: nil)), .configured, .notStarted)
    }

    /// Test that a sign-up that completes with auto sign-in carries the new user's sub
    ///
    /// - Given: Configured auth machine in `.notStarted` sign up state, and Cognito answering `SignUp` with a
    ///   confirmed user, a session and the user's sub
    /// - When:
    ///    - `Auth.signUp(username:password:options:)` is invoked
    /// - Then:
    ///    - The next step is `.completeAutoSignIn` with the session, and the result's `userID` is the sub, as for
    ///      `.done` and `.confirmUser`
    ///
    func testASignUpThatCompletesWithAutoSignInCarriesTheUserID() async throws {
        mockIdentityProvider = MockIdentityProvider(
            mockSignUpResponse: { _ in
                .init(codeDeliveryDetails: nil, session: "auto-session", userConfirmed: true, userSub: "sub-jeffb")
            }
        )

        let result = try await plugin.signUp(username: "jeffb", password: "Valid&99", options: options)

        guard case .completeAutoSignIn(let session) = result.nextStep else {
            return XCTFail("Result should be .completeAutoSignIn for next step, got \(result.nextStep)")
        }
        XCTAssertEqual(session, "auto-session")
        XCTAssertEqual(result.userID, "sub-jeffb")
    }
}
