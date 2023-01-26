//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
@testable import Amplify
@testable import AWSCognitoAuthPlugin
import AWSPluginsCore

final class AuthHubEventHandlerSignInApiTests: XCTestCase {

    var systemUnderTest: AuthHubEventHandler!

    override func setUpWithError() throws {
        try Amplify.configure(AmplifyConfiguration())
        systemUnderTest = AuthHubEventHandler()
    }

    override func tearDownWithError() throws {
        Amplify.reset()
        systemUnderTest = nil
    }

    /// - Given: A handler is subscribed to hub events
    /// - When: A signInAPI event without an data property is received
    /// - Then: No signedIn event is emitted
    func testWithoutData() throws {
        let signedInExpectation = expectation(description: "signedIn")
        signedInExpectation.isInverted = true

        _ = Amplify.Hub.listen(to: .auth) { payload in
            switch payload.eventName {
            case HubPayload.EventName.Auth.signedIn:
                signedInExpectation.fulfill()
            default:
                break
            }
        }

        let payload = HubPayload(eventName: HubPayload.EventName.Auth.signInAPI)
        Amplify.Hub.dispatch(to: .auth, payload: payload)
        wait(for: [signedInExpectation], timeout: 0.1)
    }

    /// - Given: A handler is subscribed to hub events
    /// - When: A signInAPI event is received with a data value representing a completed sign-in result
    /// - Then: A signedIn event is emitted
    func testWithSignedInSession() {
        let signedInExpectation = expectation(description: "signedIn")

        _ = Amplify.Hub.listen(to: .auth) { payload in
            switch payload.eventName {
            case HubPayload.EventName.Auth.signedIn:
                signedInExpectation.fulfill()
            default:
                break
            }
        }

        let result = AuthSignInResult(nextStep: .done)
        let operationResult: AWSAuthSignInOperation.OperationResult = .success(result)
        let payload = HubPayload(eventName: HubPayload.EventName.Auth.signInAPI,
                                 data: operationResult)
        Amplify.Hub.dispatch(to: .auth, payload: payload)
        wait(for: [signedInExpectation], timeout: 1)
    }

    /// - Given: A handler is subscribed to hub events
    /// - When: A signInAPI event is received with a data value representing a sign-up confirmation
    /// - Then: No signedIn event is emitted
    func testWaitingForSignUpConfirmation() {
        let signedInExpectation = expectation(description: "signedIn")
        signedInExpectation.isInverted = true

        _ = Amplify.Hub.listen(to: .auth) { payload in
            switch payload.eventName {
            case HubPayload.EventName.Auth.signedIn:
                signedInExpectation.fulfill()
            default:
                break
            }
        }

        let result = AuthSignInResult(nextStep: .confirmSignUp(nil))
        let operationResult: AWSAuthSignInOperation.OperationResult = .success(result)
        let payload = HubPayload(eventName: HubPayload.EventName.Auth.signInAPI,
                                 data: operationResult)
        Amplify.Hub.dispatch(to: .auth, payload: payload)
        wait(for: [signedInExpectation], timeout: 0.1)
    }

    /// - Given: A handler is subscribed to hub events
    /// - When: A confirmSignInAPI event is received with a data value representing a completed sign-in result
    /// - Then: A signedIn event is emitted
    func testSuccessfulConfirmSignInAPI() {
        let signedInExpectation = expectation(description: "signedIn")

        _ = Amplify.Hub.listen(to: .auth) { payload in
            switch payload.eventName {
            case HubPayload.EventName.Auth.signedIn:
                signedInExpectation.fulfill()
            default:
                break
            }
        }

        let result = AuthSignInResult(nextStep: .done)
        let operationResult: AWSAuthConfirmSignInOperation.OperationResult = .success(result)
        let payload = HubPayload(eventName: HubPayload.EventName.Auth.confirmSignInAPI,
                                 data: operationResult)
        Amplify.Hub.dispatch(to: .auth, payload: payload)
        wait(for: [signedInExpectation], timeout: 1)
    }

    /// - Given: A handler is subscribed to hub events
    /// - When: A confirmSignInAPI event with a data value representing a failure is received
    /// - Then: No signedIn event is emitted
    func testFailedConfirmSignInAPI() {
        let signedInExpectation = expectation(description: "signedIn")
        signedInExpectation.isInverted = true

        _ = Amplify.Hub.listen(to: .auth) { payload in
            switch payload.eventName {
            case HubPayload.EventName.Auth.signedIn:
                signedInExpectation.fulfill()
            default:
                break
            }
        }

        let operationResult: AWSAuthConfirmSignInOperation.OperationResult = .failure(
            .invalidState(UUID().uuidString, "nil")
        )
        let payload = HubPayload(eventName: HubPayload.EventName.Auth.confirmSignInAPI,
                                 data: operationResult)
        Amplify.Hub.dispatch(to: .auth, payload: payload)
        wait(for: [signedInExpectation], timeout: 1)
    }

    /// - Given: A handler is subscribed to hub events
    /// - When: A webUISignInAPI event is received with a valid operation data value.
    /// - Then: A signedIn event is emitted
    func testWebUISignInAPI() {
        let sessionExpiredExpectation = expectation(description: "sessionExpired")

        _ = Amplify.Hub.listen(to: .auth) { payload in
            switch payload.eventName {
            case HubPayload.EventName.Auth.signedIn:
                sessionExpiredExpectation.fulfill()
            default:
                break
            }
        }

        let operationResult: AWSAuthWebUISignInOperation.OperationResult = .success(
            AuthSignInResult(nextStep: .done)
        )
        let payload = HubPayload(eventName: HubPayload.EventName.Auth.webUISignInAPI,
                                 data: operationResult)
        Amplify.Hub.dispatch(to: .auth, payload: payload)
        wait(for: [sessionExpiredExpectation], timeout: 0.1)
    }

    /// - Given: A handler is subscribed to hub events
    /// - When: A webUISignInAPI event is received with a failure as its data value.
    /// - Then: No signedIn event is emitted
    func testWebUISignInApiFailure() {
        let sessionExpiredExpectation = expectation(description: "sessionExpired")
        sessionExpiredExpectation.isInverted = true

        _ = Amplify.Hub.listen(to: .auth) { payload in
            switch payload.eventName {
            case HubPayload.EventName.Auth.signedIn:
                sessionExpiredExpectation.fulfill()
            default:
                break
            }
        }

        let operationResult: AWSAuthWebUISignInOperation.OperationResult = .failure(
            AuthError.notAuthorized(UUID().uuidString, UUID().uuidString)
        )
        let payload = HubPayload(eventName: HubPayload.EventName.Auth.webUISignInAPI,
                                 data: operationResult)
        Amplify.Hub.dispatch(to: .auth, payload: payload)
        wait(for: [sessionExpiredExpectation], timeout: 0.1)
    }

    /// - Given: A handler is subscribed to hub events
    /// - When: A socialWebUISignInAPI event is received with a valid operation data value.
    /// - Then: A session expiration event is emitted
    func testSocialWebUISignInAPI() {
        let sessionExpiredExpectation = expectation(description: "sessionExpired")

        _ = Amplify.Hub.listen(to: .auth) { payload in
            switch payload.eventName {
            case HubPayload.EventName.Auth.signedIn:
                sessionExpiredExpectation.fulfill()
            default:
                break
            }
        }

        let operationResult: AWSAuthSocialWebUISignInOperation.OperationResult = .success(
            AuthSignInResult(nextStep: .done)
        )
        let payload = HubPayload(eventName: HubPayload.EventName.Auth.socialWebUISignInAPI,
                                 data: operationResult)
        Amplify.Hub.dispatch(to: .auth, payload: payload)
        wait(for: [sessionExpiredExpectation], timeout: 0.1)
    }

    /// - Given: A handler is subscribed to hub events
    /// - When: A socialWebUISignInAPI event is received with a failure as its data value.
    /// - Then: No session expiration event is emitted
    func testSocialWebUISignInApiFailure() {
        let sessionExpiredExpectation = expectation(description: "sessionExpired")
        sessionExpiredExpectation.isInverted = true

        _ = Amplify.Hub.listen(to: .auth) { payload in
            switch payload.eventName {
            case HubPayload.EventName.Auth.signedIn:
                sessionExpiredExpectation.fulfill()
            default:
                break
            }
        }

        let operationResult: AWSAuthSocialWebUISignInOperation.OperationResult = .failure(
            AuthError.unknown(UUID().uuidString)
        )
        let payload = HubPayload(eventName: HubPayload.EventName.Auth.socialWebUISignInAPI,
                                 data: operationResult)
        Amplify.Hub.dispatch(to: .auth, payload: payload)
        wait(for: [sessionExpiredExpectation], timeout: 0.1)
    }
}
