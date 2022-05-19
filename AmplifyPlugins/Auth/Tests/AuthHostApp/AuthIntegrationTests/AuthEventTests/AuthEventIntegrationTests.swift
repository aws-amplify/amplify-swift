//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
@testable import Amplify
import AWSCognitoAuthPlugin

class AuthEventIntegrationTests: AWSAuthBaseTest {
    
    var unsubscribeToken: UnsubscribeToken!

    override func setUp() {
        super.setUp()
        initializeAmplify()
        AuthSessionHelper.clearSession()
    }

    override func tearDown() {
        super.tearDown()
        Amplify.reset()
        AuthSessionHelper.clearSession()
        sleep(2)
    }

    /// Test hub event for successful signIn
    ///  of a valid user
    ///
    /// - Given: A user registered in Cognito user pool
    /// - When:
    ///    - I invoke Amplify.Auth.signIn with the username and password
    /// - Then:
    ///    - I should get a completed signIn flow event.
    ///
    func testSuccessfulSignInEvent() {

        let username = "integTest\(UUID().uuidString)"
        let password = "P123@\(UUID().uuidString)"
        
        let signInExpectation = expectation(description: "SignIn event should be fired")
        
        unsubscribeToken = Amplify.Hub.listen(to: .auth) { payload in
            switch payload.eventName {
            case HubPayload.EventName.Auth.signedIn:
                signInExpectation.fulfill()
            default:
                break
            }
        }
        
        AuthSignInHelper.registerAndSignInUser(
            username: username,
            password: password,
            email: defaultTestEmail) { didSucceed, error in
                if let unwrappedError = error {
                    XCTFail("Unable to sign in with error: \(unwrappedError)")
                }
            }
        wait(for: [signInExpectation], timeout: networkTimeout)
    }
    
    /// Test hub event for successful signOut of a valid user
    ///
    /// - Given: A user registered in Cognito user pool
    /// - When:
    ///    - I invoke Amplify.Auth.signOut with the username and password
    /// - Then:
    ///    - I should get a completed signOut flow event.
    ///
    func testSuccessfulSignOutEvent() {

        let username = "integTest\(UUID().uuidString)"
        let password = "P123@\(UUID().uuidString)"
        
        let signOutExpectation = expectation(description: "SignOut event should be fired")
        
        unsubscribeToken = Amplify.Hub.listen(to: .auth) { payload in
            switch payload.eventName {
            case HubPayload.EventName.Auth.signedOut:
                signOutExpectation.fulfill()
            default:
                break
            }
        }
        
        AuthSignInHelper.registerAndSignInUser(
            username: username,
            password: password,
            email: defaultTestEmail) { didSucceed, error in
                if let unwrappedError = error {
                    XCTFail("Unable to sign in with error: \(unwrappedError)")
                } else {
                    _ = Amplify.Auth.signOut()
                }
            }
        wait(for: [signOutExpectation], timeout: networkTimeout)
    }
    
    /// Test hub event for session expired of a valid user
    ///
    /// - Given: A user registered in Cognito user pool
    /// - When:
    ///    - I invoke Amplify.Auth.fetchAuthSession
    /// - Then:
    ///    - I should get a session expired flow event.
    ///
    func testSessionExpiredEvent() {

        let username = "integTest\(UUID().uuidString)"
        let password = "P123@\(UUID().uuidString)"
        
        let signInExpectation = expectation(description: "SignIn event should be fired")
        let sessionExpiredExpectation = expectation(description: "Session expired event should be fired")
        
        unsubscribeToken = Amplify.Hub.listen(to: .auth) { payload in
            switch payload.eventName {
            case HubPayload.EventName.Auth.signedIn:
                signInExpectation.fulfill()
            case HubPayload.EventName.Auth.sessionExpired:
                sessionExpiredExpectation.fulfill()
            default:
                break
            }
        }
        
        AuthSignInHelper.registerAndSignInUser(
            username: username,
            password: password,
            email: defaultTestEmail) { didSucceed, error in
                if let unwrappedError = error {
                    XCTFail("Unable to sign in with error: \(unwrappedError)")
                } else {
                    Amplify.Auth.fetchAuthSession { _ in
                        // Manually invalidate the tokens and then try to fetch the session.
                        AuthSessionHelper.invalidateSession(with: self.amplifyConfiguration)
                        Amplify.Auth.fetchAuthSession { _ in }
                    }
                }
            }
        wait(for: [signInExpectation, sessionExpiredExpectation], timeout: networkTimeout, enforceOrder: true)
    }

}
