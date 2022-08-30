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
    let networkTimeout = TimeInterval(5)
    var mockHostedUIResult: Result<[URLQueryItem], HostedUIError>!
    var mockTokenResult = ["id_token": AWSCognitoUserPoolTokens.testData.idToken,
                           "access_token": AWSCognitoUserPoolTokens.testData.accessToken,
                           "refresh_token": AWSCognitoUserPoolTokens.testData.refreshToken,
                           "expires_in": 10] as [String: Any]
    var mockState = "someState"
    var mockProof = "someProof"
    var mockJson: Data!

    var configuration = HostedUIConfigurationData(clientId: "clientId", oauth: .init(
        domain: "cognitodomain",
        scopes: ["name"],
        signInRedirectURI: "myapp://",
        signOutRedirectURI: "myapp://"))
    let initialState = AuthState.configured(.signedOut(.init(lastKnownUserName: nil)), .configured)

    func urlSessionMock() -> URLSession {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [MockURLProtocol.self]
        return URLSession(configuration: configuration)
    }

    override func setUp() {
        plugin = AWSCognitoAuthPlugin()
        mockJson = try! JSONSerialization.data(withJSONObject: mockTokenResult)
        MockURLProtocol.requestHandler = { _ in
            return (HTTPURLResponse(), self.mockJson)
        }

        func sessionFactory() -> HostedUISessionBehavior {
            MockHostedUISession(result: mockHostedUIResult)
        }

        func mockRandomString() -> RandomStringBehavior {
            return MockRandomStringGenerator(mockString: mockState, mockUUID: mockState)
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
    }

    @MainActor
    func testSuccessfulSignIn() async throws {
        mockHostedUIResult = .success([
            .init(name: "state", value: mockState),
            .init(name: "code", value: mockProof)
        ])
        let result = try await plugin?.signInWithWebUI(presentationAnchor: ASPresentationAnchor(), options: nil)
        XCTAssertTrue(result!.isSignedIn)
    }

    @MainActor
    func testUserCancelSignIn() async {
        mockHostedUIResult = .failure(.cancelled)
        let expectation  = expectation(description: "SignIn operation should complete")
        do {
            _ = try await plugin?.signInWithWebUI(presentationAnchor: ASPresentationAnchor(), options: nil)
            XCTFail("Should not succeed")
        } catch {
            guard case AuthError.service(_, _, let underlyingError) = error,
                  case .userCancelled = (underlyingError as? AWSCognitoAuthError) else {
                XCTFail("Should not fail with error = \(error)")
                return
            }
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: networkTimeout)
    }

    @MainActor
    func testRestartAfterError() async {
        mockHostedUIResult = .failure(.cancelled)
        let errorExpectation  = expectation(description: "SignIn operation should complete")
        do {
            let result = try await plugin?.signInWithWebUI(presentationAnchor: ASPresentationAnchor(), options: nil)
            XCTFail("Should not succeed")
        } catch {
            guard case AuthError.service(_, _, let underlyingError) = error,
                  case .userCancelled = (underlyingError as? AWSCognitoAuthError) else {
                XCTFail("Should not fail with error = \(error)")
                return
            }
            errorExpectation.fulfill()
        }

        wait(for: [errorExpectation], timeout: networkTimeout)
        mockHostedUIResult = .success([
            .init(name: "state", value: mockState),
            .init(name: "code", value: mockProof)
        ])
        let signInExpectation = expectation(description: "SignIn operation should complete")
        do {
            let result = try await plugin?.signInWithWebUI(presentationAnchor: ASPresentationAnchor(), options: nil)
            XCTAssertTrue(result!.isSignedIn)
            signInExpectation.fulfill()
        } catch {
            XCTFail("Should not fail with error = \(error)")
        }
        wait(for: [signInExpectation], timeout: networkTimeout)
    }

    @MainActor
    func testInvalidCodeSignIn() async {
        mockHostedUIResult = .success([
            .init(name: "state", value: "differentState"),
            .init(name: "code", value: mockProof)
        ])
        let expectation  = expectation(description: "SignIn operation should complete")
        do {
            _ = try await plugin?.signInWithWebUI(presentationAnchor: ASPresentationAnchor(), options: nil)
            XCTFail("Should not succeed")
        } catch {
            guard case AuthError.service = error else {
                XCTFail("Should not fail with error = \(error)")
                return
            }
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: networkTimeout)
    }

    @MainActor
    func testInvalidPresentationContextError() async {
        mockHostedUIResult = .failure(.invalidContext)
        let expectation  = expectation(description: "SignIn operation should complete")
        do {
            _ = try await plugin?.signInWithWebUI(presentationAnchor: ASPresentationAnchor(), options: nil)
            XCTFail("Should not succeed")
        } catch {
            guard case AuthError.invalidState = error else {
                XCTFail("Should not fail with error = \(error)")
                return
            }
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: networkTimeout)
    }

    @MainActor
    func testTokenParsingFailure() async {
        mockHostedUIResult = .success([
            .init(name: "state", value: mockState),
            .init(name: "code", value: mockProof)
        ])
        mockTokenResult = [
            "refresh_token": AWSCognitoUserPoolTokens.testData.refreshToken,
            "expires_in": 10] as [String: Any]
        mockJson = try! JSONSerialization.data(withJSONObject: mockTokenResult)
        MockURLProtocol.requestHandler = { _ in
            return (HTTPURLResponse(), self.mockJson)
        }

        let expectation  = expectation(description: "SignIn operation should complete")
        do {
            _ = try await plugin?.signInWithWebUI(presentationAnchor: ASPresentationAnchor(), options: nil)
            XCTFail("Should not succeed")
        } catch {
            guard case AuthError.service = error else {
                XCTFail("Should not fail with error = \(error)")
                return
            }
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: networkTimeout)
    }

    @MainActor
    func testTokenErrorResponse() async {
        mockHostedUIResult = .success([
            .init(name: "state", value: mockState),
            .init(name: "code", value: mockProof)
        ])
        mockTokenResult = [
            "error": "invalid_grant",
            "error_description": "Some error"] as [String: Any]
        mockJson = try! JSONSerialization.data(withJSONObject: mockTokenResult)
        MockURLProtocol.requestHandler = { _ in
            return (HTTPURLResponse(), self.mockJson)
        }

        let expectation  = expectation(description: "SignIn operation should complete")
        do {
            _ = try await plugin?.signInWithWebUI(presentationAnchor: ASPresentationAnchor(), options: nil)
            XCTFail("Should not succeed")
        } catch {
            guard case AuthError.service = error else {
                XCTFail("Should not fail with error = \(error)")
                return
            }
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: networkTimeout)
    }

}
