//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
@testable import Amplify
@testable import AWSCognitoAuthPlugin

class AuthHubEventHandlerTests: XCTestCase {

    var authHandler: AuthHubEventHandler!
    override func setUp() {
        try? Amplify.configure()
        authHandler = AuthHubEventHandler()
    }

    override func tearDown() async throws {
        await Amplify.reset()
        authHandler = nil
    }

    /// Test whether HubEvent emits a signedIn event for mocked signIn operation
    ///
    /// - Given: A listener to hub events
    /// - When:
    ///    - I mock a succesful sign in operation event
    /// - Then:
    ///    - I should receive a signedIn hub event
    ///
    func testSignedInHubEvent() {

        let hubEventExpectation = expectation(description: "Should receive the hub event")
        _ = Amplify.Hub.listen(to: .auth) { payload in
            switch payload.eventName {
            case HubPayload.EventName.Auth.signedIn:
                hubEventExpectation.fulfill()
            default:
                break
            }
        }
        mockSuccessfulSignedInEvent()
        wait(for: [hubEventExpectation], timeout: 10)
    }

    /* TODO: Enable these tests when the API's have been implemented

    /// Test whether HubEvent emits a mocked signedIn event for webUI signIn
    ///
    /// - Given: A listener to hub events
    /// - When:
    ///    - I mock a succesful webui signIn operation event
    /// - Then:
    ///    - I should receive a signedIn hub event
    ///
    func testWebUISignedInHubEvent() {
        _ = AuthHubEventHandler()
        let hubEventExpectation = expectation(description: "Should receive the hub event")
        _ = Amplify.Hub.listen(to: .auth) { payload in
            switch payload.eventName {
            case HubPayload.EventName.Auth.signedIn:
                hubEventExpectation.fulfill()
            default:
                break
            }
        }
        mockSuccessfulWebUISignedInEvent()
        wait(for: [hubEventExpectation], timeout: 10)
    }

    /// Test whether HubEvent emits a mocked signedIn event for social provider signIn
    ///
    /// - Given: A listener to hub events
    /// - When:
    ///    - I mock a succesful social provider webui signIn operation event
    /// - Then:
    ///    - I should receive a signedIn hub event
    ///
    func testSocialWebUISignedInHubEvent() {
        _ = AuthHubEventHandler()
        let hubEventExpectation = expectation(description: "Should receive the hub event")
        _ = Amplify.Hub.listen(to: .auth) { payload in
            switch payload.eventName {
            case HubPayload.EventName.Auth.signedIn:
                hubEventExpectation.fulfill()
            default:
                break
            }
        }
        mockSuccessfulSocialWebUISignedInEvent()
        wait(for: [hubEventExpectation], timeout: 10)
    }
    
    private func mockSuccessfulSocialWebUISignedInEvent() {
        let mockResult = AuthSignInResult(nextStep: .done)
        let mockEvent = AWSAuthSocialWebUISignInOperation.OperationResult.success(mockResult)
        let mockRequest = AuthWebUISignInRequest(presentationAnchor: UIWindow(),
                                                 authProvider: .amazon,
                                                 options: AuthWebUISignInRequest.Options())
        let mockContext = AmplifyOperationContext(operationId: UUID(), request: mockRequest)
        let mockPayload = HubPayload(eventName: HubPayload.EventName.Auth.socialWebUISignInAPI,
                                     context: mockContext,
                                     data: mockEvent)
        Amplify.Hub.dispatch(to: .auth, payload: mockPayload)

    }

    private func mockSuccessfulWebUISignedInEvent() {
        let mockResult = AuthSignInResult(nextStep: .done)
        let mockEvent = AWSAuthWebUISignInOperation.OperationResult.success(mockResult)
        let mockRequest = AuthWebUISignInRequest(presentationAnchor: UIWindow(),
                                                 options: AuthWebUISignInRequest.Options())
        let mockContext = AmplifyOperationContext(operationId: UUID(), request: mockRequest)
        let mockPayload = HubPayload(eventName: HubPayload.EventName.Auth.webUISignInAPI,
                                     context: mockContext,
                                     data: mockEvent)
        Amplify.Hub.dispatch(to: .auth, payload: mockPayload)

    }
     */
    private func mockSuccessfulSignedInEvent() {
        let mockResult = AuthSignInResult(nextStep: .done)
        let mockEvent = AWSAuthSignInOperation.OperationResult.success(mockResult)
        let mockRequest = AuthSignInRequest(username: "username",
                                            password: "password",
                                            options: AuthSignInRequest.Options())
        let mockContext = AmplifyOperationContext(operationId: UUID(), request: mockRequest)
        let mockPayload = HubPayload(eventName: HubPayload.EventName.Auth.signInAPI,
                                     context: mockContext,
                                     data: mockEvent)
        Amplify.Hub.dispatch(to: .auth, payload: mockPayload)

    }

}
