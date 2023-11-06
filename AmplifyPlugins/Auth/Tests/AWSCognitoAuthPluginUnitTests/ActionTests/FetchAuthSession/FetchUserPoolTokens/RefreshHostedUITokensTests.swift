//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

#if os(iOS) || os(macOS)

@testable import AWSCognitoAuthPlugin
import AWSCognitoIdentityProvider
import AWSPluginsCore
import XCTest

class RefreshHostedUITokensTests: XCTestCase {
    private let tokenResult: [String: Any] = [
        "id_token": AWSCognitoUserPoolTokens.testData.idToken,
        "access_token": AWSCognitoUserPoolTokens.testData.accessToken,
        "refresh_token": AWSCognitoUserPoolTokens.testData.refreshToken,
        "expires_in": 10
    ]
    
    private var hostedUIEnvironment: HostedUIEnvironment {
        BasicHostedUIEnvironment(
            configuration: .init(
                clientId: "clientId",
                oauth: .init(
                    domain: "cognitodomain",
                    scopes: ["name"],
                    signInRedirectURI: "myapp://",
                    signOutRedirectURI: "myapp://"
                )
            ),
            hostedUISessionFactory: sessionFactory,
            urlSessionFactory: urlSessionMock,
            randomStringFactory: mockRandomString
        )
    }
    
    override func setUp() {
        let result = try! JSONSerialization.data(withJSONObject: tokenResult)
        MockURLProtocol.requestHandler = { _ in
            return (HTTPURLResponse(), result)
        }
    }
    
    override func tearDown() {
        MockURLProtocol.requestHandler = nil
    }

    /// Given: A RefreshHostedUITokens action
    /// When: execute is invoked with a valid response
    /// Then: A RefreshSessionEvent.refreshIdentityInfo is dispatched
    func testExecute_withValidResponse_shouldDispatchRefreshEvent() async {
        let expectation = expectation(description: "refreshHostedUITokens")
        let action = RefreshHostedUITokens(existingSignedIndata: .testData)
        action.execute(
            withDispatcher: MockDispatcher { event in
                guard let event = event as? RefreshSessionEvent,
                      case .refreshIdentityInfo(let data, _) = event.eventType else {
                    XCTFail("Failed to refresh tokens")
                    expectation.fulfill()
                    return
                }

                XCTAssertEqual(data.cognitoUserPoolTokens.idToken, self.tokenResult["id_token"] as? String)
                XCTAssertEqual(data.cognitoUserPoolTokens.accessToken, self.tokenResult["access_token"] as? String)
                XCTAssertEqual(data.cognitoUserPoolTokens.refreshToken, self.tokenResult["refresh_token"] as? String)
                expectation.fulfill()
            },
            environment: Defaults.makeDefaultAuthEnvironment(
                userPoolFactory: identityProviderFactory,
                hostedUIEnvironment: hostedUIEnvironment
            )
        )

        await fulfillment(of: [expectation], timeout: 1)
    }
    
    /// Given: A RefreshHostedUITokens action
    /// When: execute is invoked and throws a HostedUIError
    /// Then: A RefreshSessionEvent.throwError is dispatched with .service
    func testExecute_withHostedUIError_shouldDispatchErrorEvent() async {
        let expectedError = HostedUIError.serviceMessage("Something went wrong")
        MockURLProtocol.requestHandler = { _ in
            throw expectedError
        }
        
        let expectation = expectation(description: "refreshHostedUITokens")
        let action = RefreshHostedUITokens(existingSignedIndata: .testData)
        action.execute(
            withDispatcher: MockDispatcher { event in
                guard let event = event as? RefreshSessionEvent,
                      case let .throwError(error) = event.eventType else {
                    XCTFail("Expected failure due to Service Error")
                    expectation.fulfill()
                    return
                }

                XCTAssertEqual(error, .service(expectedError))
                expectation.fulfill()
            },
            environment: Defaults.makeDefaultAuthEnvironment(
                userPoolFactory: identityProviderFactory,
                hostedUIEnvironment: hostedUIEnvironment
            )
        )

        await fulfillment(of: [expectation], timeout: 1)
    }
    
    /// Given: A RefreshHostedUITokens action
    /// When: execute is invoked and returns empty data
    /// Then: A RefreshSessionEvent.throwError is dispatched with .service
    func testExecute_withEmptyData_shouldDispatchErrorEvent() async {
        MockURLProtocol.requestHandler = { _ in
            return (HTTPURLResponse(), Data())
        }
        
        let expectation = expectation(description: "refreshHostedUITokens")
        let action = RefreshHostedUITokens(existingSignedIndata: .testData)
        action.execute(
            withDispatcher: MockDispatcher { event in
                guard let event = event as? RefreshSessionEvent,
                      case let .throwError(error) = event.eventType else {
                    XCTFail("Expected failure due to Invalid Tokens")
                    expectation.fulfill()
                    return
                }

                guard case .service(let serviceError) = error else {
                    XCTFail("Expected FetchSessionError.service, got \(error)")
                    expectation.fulfill()
                    return
                }
                
                
                XCTAssertEqual((serviceError as NSError).code, NSPropertyListReadCorruptError)
                expectation.fulfill()
            },
            environment: Defaults.makeDefaultAuthEnvironment(
                userPoolFactory: identityProviderFactory,
                hostedUIEnvironment: hostedUIEnvironment
            )
        )

        await fulfillment(of: [expectation], timeout: 1)
    }
    
    /// Given: A RefreshHostedUITokens action
    /// When: execute is invoked and returns data that is invalid for tokens
    /// Then: A RefreshSessionEvent.throwError is dispatched with .invalidTokens
    func testExecute_withInvalidTokens_shouldDispatchErrorEvent() async {
        let result: [String: Any] = [
            "key": "value"
        ]
        MockURLProtocol.requestHandler = { _ in
            return (HTTPURLResponse(), try! JSONSerialization.data(withJSONObject: result))
        }
        
        let expectation = expectation(description: "refreshHostedUITokens")
        let action = RefreshHostedUITokens(existingSignedIndata: .testData)
        action.execute(
            withDispatcher: MockDispatcher { event in
                guard let event = event as? RefreshSessionEvent,
                      case let .throwError(error) = event.eventType else {
                    XCTFail("Expected failure due to Invalid Tokens")
                    expectation.fulfill()
                    return
                }

               
                XCTAssertEqual(error, .invalidTokens)
                expectation.fulfill()
            },
            environment: Defaults.makeDefaultAuthEnvironment(
                userPoolFactory: identityProviderFactory,
                hostedUIEnvironment: hostedUIEnvironment
            )
        )

        await fulfillment(of: [expectation], timeout: 1)
    }
    
    /// Given: A RefreshHostedUITokens action
    /// When: execute is invoked and returns data representing an error
    /// Then: A RefreshSessionEvent.throwError is dispatched with .service
    func testExecute_withErrorResponse_shouldDispatchErrorEvent() async {
        let result: [String: Any] = [
            "error": "Error.",
            "error_description": "Something went wrong"
        ]
        MockURLProtocol.requestHandler = { _ in
            return (HTTPURLResponse(), try! JSONSerialization.data(withJSONObject: result))
        }
        
        let expectation = expectation(description: "refreshHostedUITokens")
        let action = RefreshHostedUITokens(existingSignedIndata: .testData)
        action.execute(
            withDispatcher: MockDispatcher { event in
                guard let event = event as? RefreshSessionEvent,
                      case let .throwError(error) = event.eventType else {
                    XCTFail("Expected failure due to Invalid Tokens")
                    expectation.fulfill()
                    return
                }

                guard case .service(let serviceError) = error,
                      case .serviceMessage(let errorMessage) = serviceError as? HostedUIError else {
                    XCTFail("Expected HostedUIError.serviceMessage, got \(error)")
                    expectation.fulfill()
                    return
                }
                
                
                XCTAssertEqual(errorMessage, "Error. Something went wrong")
                expectation.fulfill()
            },
            environment: Defaults.makeDefaultAuthEnvironment(
                userPoolFactory: identityProviderFactory,
                hostedUIEnvironment: hostedUIEnvironment
            )
        )

        await fulfillment(of: [expectation], timeout: 1)
    }
    
    /// Given: A RefreshHostedUITokens action
    /// When: execute is invoked without a HostedUIEnvironment
    /// Then: A RefreshSessionEvent.throwError is dispatched with .noUserPool
    func testExecute_withoutHostedUIEnvironment_shouldDispatchErrorEvent() async {
        let expectation = expectation(description: "noHostedUIEnvironment")
        let action = RefreshHostedUITokens(existingSignedIndata: .testData)
        action.execute(
            withDispatcher: MockDispatcher { event in
                guard let event = event as? RefreshSessionEvent,
                      case let .throwError(error) = event.eventType else {
                    XCTFail("Expected failure due to no HostedUIEnvironment")
                    expectation.fulfill()
                    return
                }

                XCTAssertEqual(error, .noUserPool)
                expectation.fulfill()
            },
            environment: Defaults.makeDefaultAuthEnvironment(
                userPoolFactory: identityProviderFactory,
                hostedUIEnvironment: nil
            )
        )

        await fulfillment(of: [expectation], timeout: 1)
    }
    
    /// Given: A RefreshHostedUITokens action
    /// When: execute is invoked without a UserPoolEnvironment
    /// Then: A RefreshSessionEvent.throwError is dispatched with .noUserPool
    func testExecute_withoutUserPoolEnvironment_shouldDispatchErrorEvent() async {
        let expectation = expectation(description: "noUserPoolEnvironment")
        let action = RefreshHostedUITokens(existingSignedIndata: .testData)
        action.execute(
            withDispatcher: MockDispatcher { event in
                guard let event = event as? RefreshSessionEvent,
                      case let .throwError(error) = event.eventType else {
                    XCTFail("Expected failure due to no UserPoolEnvironment")
                    expectation.fulfill()
                    return
                }
                
                XCTAssertEqual(error, .noUserPool)
                expectation.fulfill()
            },
            environment: MockInvalidEnvironment()
        )

        await fulfillment(of: [expectation], timeout: 1)
    }

    private func identityProviderFactory() throws -> CognitoUserPoolBehavior {
        return MockIdentityProvider(
            mockInitiateAuthResponse: { _ in
                return InitiateAuthOutputResponse(
                    authenticationResult: .init(
                        accessToken: "accessTokenNew",
                        expiresIn: 100,
                        idToken: "idTokenNew",
                        refreshToken: "refreshTokenNew")
                )
            }
        )
    }
    
    private func urlSessionMock() -> URLSession {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [MockURLProtocol.self]
        return URLSession(configuration: configuration)
    }
    
    private func sessionFactory() -> HostedUISessionBehavior {
        MockHostedUISession(result: .failure(.cancelled))
    }

    private func mockRandomString() -> RandomStringBehavior {
        return MockRandomStringGenerator(
            mockString: "mockString",
            mockUUID: "mockUUID"
        )
    }
}
#endif
