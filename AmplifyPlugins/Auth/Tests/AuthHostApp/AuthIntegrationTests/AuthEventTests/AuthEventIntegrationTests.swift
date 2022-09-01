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

    override func tearDown() async throws {
        try await super.tearDown()
        await Amplify.reset()
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
    func testSuccessfulSignInEvent() async throws {

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

        _ = try await AuthSignInHelper.registerAndSignInUser(
            username: username,
            password: password,
            email: defaultTestEmail)
        
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
    func testSuccessfulSignOutEvent() async throws {

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

        _ = try await AuthSignInHelper.registerAndSignInUser(
            username: username,
            password: password,
            email: defaultTestEmail)
        try await Amplify.Auth.signOut()
    }

    /// Test hub event for session expired of a valid user
    ///
    /// - Given: A user registered in Cognito user pool
    /// - When:
    ///    - I invoke Amplify.Auth.fetchAuthSession
    /// - Then:
    ///    - I should get a session expired flow event.
    ///
    func testSessionExpiredEvent() async throws {
        throw XCTSkip("TODO: fix this test. We need to find a way to mock credential store")
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

        do {
            _ = try await AuthSignInHelper.registerAndSignInUser(
                username: username,
                password: password,
                email: defaultTestEmail)
        } catch {
            _ = try await Amplify.Auth.fetchAuthSession()
            AuthSessionHelper.invalidateSession(with: self.amplifyConfiguration)
            _ = try await Amplify.Auth.fetchAuthSession()
        }
        wait(for: [signInExpectation, sessionExpiredExpectation], timeout: networkTimeout, enforceOrder: true)
    }

    /// Test hub event for successful deletion of a valid user
    ///
    /// - Given: A user registered in Cognito user pool
    /// - When:
    ///    - I invoke Amplify.Auth.deleteUser
    /// - Then:
    ///    - I should get successful deleteUser flow event
    ///
    func testSuccessfulDeletedUserEvent() async throws {

        let username = "integTest\(UUID().uuidString)"
        let password = "P123@\(UUID().uuidString)"

        let signInExpectation = expectation(description: "SignIn operation should complete")
        let deletedUserExpectation = expectation(description: "UserDeleted event should be fired")

        unsubscribeToken = Amplify.Hub.listen(to: .auth) { payload in
            switch payload.eventName {
            case HubPayload.EventName.Auth.signedIn:
                signInExpectation.fulfill()
            case HubPayload.EventName.Auth.userDeleted:
                deletedUserExpectation.fulfill()
            default:
                break
            }
        }

        _ = try await AuthSignInHelper.registerAndSignInUser(
            username: username,
            password: password,
            email: defaultTestEmail)
        wait(for: [signInExpectation], timeout: networkTimeout)

        do {
            try await Amplify.Auth.deleteUser()
            print("Success deleteUser")
        } catch {
            XCTFail("deleteUser should not fail - \(error)")
        }
        wait(for: [deletedUserExpectation], timeout: networkTimeout)
    }
}
