//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

import XCTest
@testable import Amplify
@testable import AWSCognitoAuthPlugin
import AWSPluginsCore

final class AuthHubEventHandlerFetchSessionApiTests: XCTestCase {

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
    /// - When: A fetchSessionAPI event without any data is received
    /// - Then: No session expiration event is emitted
    func testWithoutData() {
        let sessionExpiredExpectation = expectation(description: "sessionExpired")
        sessionExpiredExpectation.isInverted = true

        _ = Amplify.Hub.listen(to: .auth) { payload in
            switch payload.eventName {
            case HubPayload.EventName.Auth.sessionExpired:
                sessionExpiredExpectation.fulfill()
            default:
                break
            }
        }

        Amplify.Hub.dispatch(to: .auth, payload: HubPayload(eventName: HubPayload.EventName.Auth.fetchSessionAPI))
        wait(for: [sessionExpiredExpectation], timeout: 0.1)
    }

    /// - Given: A handler is subscribed to hub events
    /// - When: A fetchSessionAPI event with an unexpected data value is received
    /// - Then: No session expiration event is emitted
    func testUnexpectedValue() {
        let sessionExpiredExpectation = expectation(description: "sessionExpired")
        sessionExpiredExpectation.isInverted = true

        _ = Amplify.Hub.listen(to: .auth) { payload in
            switch payload.eventName {
            case HubPayload.EventName.Auth.sessionExpired:
                sessionExpiredExpectation.fulfill()
            default:
                break
            }
        }

        Amplify.Hub.dispatch(to: .auth, payload: HubPayload(eventName: HubPayload.EventName.Auth.fetchSessionAPI,
                                                            data: UUID().uuidString))
        wait(for: [sessionExpiredExpectation], timeout: 0.1)
    }

    /// - Given: A handler is subscribed to hub events
    /// - When: A fetchSessionAPI event with a OperationResult data value without a valid tokens response is received
    /// - Then: A session expiration event is emitted
    func testWithoutValidSessionTokens() {
        let sessionExpiredExpectation = expectation(description: "sessionExpired")

        _ = Amplify.Hub.listen(to: .auth) { payload in
            switch payload.eventName {
            case HubPayload.EventName.Auth.sessionExpired:
                sessionExpiredExpectation.fulfill()
            default:
                break
            }
        }

        let session = MockAuthSession(isSignedIn: false, tokens: .failure(.sessionExpired(UUID().uuidString, "nil")))
        let operationResult: AWSAuthFetchSessionOperation.OperationResult = .success(session)
        let payload = HubPayload(eventName: HubPayload.EventName.Auth.fetchSessionAPI,
                                 data: operationResult)
        Amplify.Hub.dispatch(to: .auth, payload: payload)
        wait(for: [sessionExpiredExpectation], timeout: 0.1)
    }

    /// - Given: A handler is subscribed to hub events
    /// - When: A fetchSessionAPI event is received with a data value not conforming to AuthCognitoTokensProvider
    /// - Then: No session expiration event is emitted
    func testNonAuthCognitoTokensProvider() {
        let sessionExpiredExpectation = expectation(description: "sessionExpired")
        sessionExpiredExpectation.isInverted = true

        _ = Amplify.Hub.listen(to: .auth) { payload in
            switch payload.eventName {
            case HubPayload.EventName.Auth.sessionExpired:
                sessionExpiredExpectation.fulfill()
            default:
                break
            }
        }

        struct MockCustomAuthSession: AuthSession {
            var isSignedIn: Bool
        }
        let session = MockCustomAuthSession(isSignedIn: false)
        let operationResult: AWSAuthFetchSessionOperation.OperationResult = .success(session)
        let payload = HubPayload(eventName: HubPayload.EventName.Auth.fetchSessionAPI,
                                 data: operationResult)
        Amplify.Hub.dispatch(to: .auth, payload: payload)
        wait(for: [sessionExpiredExpectation], timeout: 0.1)
    }

    /// - Given: A handler is subscribed to hub events
    /// - When: A fetchSessionAPI event is received with a MockAuthSession with valid tokens
    /// - Then: No session expiration event is emitted
    func testTokensContainer() {
        let sessionExpiredExpectation = expectation(description: "sessionExpired")
        sessionExpiredExpectation.isInverted = true

        _ = Amplify.Hub.listen(to: .auth) { payload in
            switch payload.eventName {
            case HubPayload.EventName.Auth.sessionExpired:
                sessionExpiredExpectation.fulfill()
            default:
                break
            }
        }

        let session = MockAuthSession(isSignedIn: false, tokens: .success(MockAuthCognitoTokens()))
        let operationResult: AWSAuthFetchSessionOperation.OperationResult = .success(session)
        let payload = HubPayload(eventName: HubPayload.EventName.Auth.fetchSessionAPI,
                                 data: operationResult)
        Amplify.Hub.dispatch(to: .auth, payload: payload)
        wait(for: [sessionExpiredExpectation], timeout: 0.1)
    }

    /// - Given: A handler is subscribed to hub events
    /// - When: A fetchSessionAPI event with a OperationResult data value with a valid tokens response is received
    /// - Then: A session expiration event is emitted
    func testWithValidSessionTokens() {
        let sessionExpiredExpectation = expectation(description: "sessionExpired")

        _ = Amplify.Hub.listen(to: .auth) { payload in
            switch payload.eventName {
            case HubPayload.EventName.Auth.sessionExpired:
                sessionExpiredExpectation.fulfill()
            default:
                break
            }
        }

        let session = MockAuthSession(isSignedIn: false, tokens: .failure(.sessionExpired(UUID().uuidString, "nil")))
        let operationResult: AWSAuthFetchSessionOperation.OperationResult = .success(session)
        let payload = HubPayload(eventName: HubPayload.EventName.Auth.fetchSessionAPI,
                                 data: operationResult)
        Amplify.Hub.dispatch(to: .auth, payload: payload)
        wait(for: [sessionExpiredExpectation], timeout: 0.1)
    }

    /// - Given: A handler is subscribed to hub events
    /// - When: A fetchSessionAPI event is received with a OperationResult failure.
    /// - Then: No session expiration event is emitted
    func testWithFailedOperationResult() {
        let sessionExpiredExpectation = expectation(description: "sessionExpired")
        sessionExpiredExpectation.isInverted = true

        _ = Amplify.Hub.listen(to: .auth) { payload in
            switch payload.eventName {
            case HubPayload.EventName.Auth.sessionExpired:
                sessionExpiredExpectation.fulfill()
            default:
                break
            }
        }

        let operationResult: AWSAuthFetchSessionOperation.OperationResult = .failure(
            .invalidState(UUID().uuidString, "nil")
        )
        let payload = HubPayload(eventName: HubPayload.EventName.Auth.fetchSessionAPI,
                                 data: operationResult)
        Amplify.Hub.dispatch(to: .auth, payload: payload)
        wait(for: [sessionExpiredExpectation], timeout: 0.1)
    }
}
