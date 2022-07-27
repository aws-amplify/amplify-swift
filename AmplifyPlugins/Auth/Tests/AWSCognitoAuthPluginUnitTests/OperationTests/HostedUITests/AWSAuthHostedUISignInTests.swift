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
import AuthenticationServices

class AWSAuthHostedUISignInTests: XCTestCase {

    var plugin: AWSCognitoAuthPlugin?

    override func setUp() {
        plugin = AWSCognitoAuthPlugin()
    }

    var initialState: AuthState {
        AuthState.configured(.signedOut(.init(lastKnownUserName: nil)), .configured)
    }

    func urlSessionMock() -> URLSession {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [MockURLProtocol.self]
        return URLSession(configuration: configuration)
    }

    func testSuccessfulSignIn() {
        let configuration = HostedUIConfigurationData(clientId: "clientId", oauth: .init(
            domain: "cognitodomain.com",
            scopes: ["name"],
            signInRedirectURI: "myapp://",
            signOutRedirectURI: "myapp://"))

        let state = "someState"
        let proof = "someProof"
        func sessionFactory() -> HostedUISessionBehavior {
            MockHostedUISession(result: .success(
                [
                    .init(name: "state", value: state),
                    .init(name: "code", value: proof)
                ]
            ))
        }

        func mockRandomString() -> RandomStringBehavior {
            return MockRandomStringGenerator(mockString: proof, mockUUID: state)
        }

        let mockTokens = AWSCognitoUserPoolTokens.mockData
        let mockTokenResult = ["id_token": mockTokens.idToken,
                               "access_token": mockTokens.accessToken,
                               "refresh_token": mockTokens.refreshToken,
                               "expires_in": 10] as [String : Any]
        let mockJson = try! JSONSerialization.data(withJSONObject: mockTokenResult)
        MockURLProtocol.requestHandler = { request in
            return (HTTPURLResponse(), mockJson)
        }

        let environment = BasicHostedUIEnvironment(configuration: configuration,
                                                   hostedUISessionFactory: sessionFactory,
                                                   urlSessionFactory: urlSessionMock,
                                                   randomStringFactory: mockRandomString)
        let authEnvironment = Defaults.makeDefaultAuthEnvironment(hostedUIEnvironment: environment)
        let stateMachine = Defaults.authStateMachineWith(environment: authEnvironment,
                                                         initialState: initialState)


        plugin?.configure(
            authConfiguration: Defaults.makeDefaultAuthConfigData(withHostedUI: configuration),
            authEnvironment: authEnvironment,
            authStateMachine: stateMachine,
            credentialStoreStateMachine: Defaults.makeDefaultCredentialStateMachine(),
            hubEventHandler: MockAuthHubEventBehavior())

        let expectation  = expectation(description: "")
        _ = plugin?.signInWithWebUI(presentationAnchor: ASPresentationAnchor(),
                               options: nil) { result in
            defer {
                expectation.fulfill()
            }
            switch result {
            case .success(let result):
                XCTAssertTrue(result.isSignedIn)
            case .failure(let error):
                XCTFail("Should not fail with error = \(error)")
            }

        }
        wait(for: [expectation], timeout: 10)
    }
    
}
