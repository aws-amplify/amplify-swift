//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

@testable import AWSCognitoAuthPlugin
import AWSCognitoIdentityProvider
import AWSPluginsCore
import XCTest

class ShowHostedUISignOutTests: XCTestCase {
    private var mockHostedUIResult: Result<[URLQueryItem], HostedUIError>!
    private var signOutRedirectURI: String!
    
    override func setUp() {
        signOutRedirectURI = "myapp://"
        mockHostedUIResult = .success([.init(name: "key", value: "value")])
    }
    
    override func tearDown() {
        signOutRedirectURI = nil
        mockHostedUIResult = nil
    }

    /// Given: A ShowHostedUISignOut action with global sign out set to true
    /// When: execute is invoked with a success result
    /// Then: A .signOutGlobally event is dispatched with a nil error
    func testExecute_withGlobalSignOut_andSuccessResult_shouldDispatchSignOutEvent() async {
        let expectation = expectation(description: "showHostedUISignOut")
        let signInData = SignedInData.testData
        let action = ShowHostedUISignOut(
            signOutEvent: SignOutEventData(globalSignOut: true),
            signInData: signInData
        )

        await action.execute(
            withDispatcher: MockDispatcher { event in
                guard let event = event as? SignOutEvent,
                      case .signOutGlobally(let data, let error) = event.eventType else {
                    XCTFail("Expected SignOutEvent.signOutGlobally, got \(event)")
                    expectation.fulfill()
                    return
                }

                XCTAssertNil(error)
                XCTAssertEqual(data, signInData)
                self.validateDebugInformation(signInData: signInData, action: action)
                
                expectation.fulfill()
            },
            environment: Defaults.makeDefaultAuthEnvironment(
                userPoolFactory: identityProviderFactory,
                hostedUIEnvironment: hostedUIEnvironment
            )
        )

        await fulfillment(of: [expectation], timeout: 1)
    }
    
    /// Given: A ShowHostedUISignOut action with global sign out set to false
    /// When: execute is invoked with a success result
    /// Then: A .revokeToken event is dispatched
    func testExecute_withLocalSignOut_andSuccessResult_shouldDispatchSignOutEvent() async {
        let expectation = expectation(description: "showHostedUISignOut")
        let signInData = SignedInData.testData
        let action = ShowHostedUISignOut(
            signOutEvent: SignOutEventData(globalSignOut: false),
            signInData: signInData
        )

        await action.execute(
            withDispatcher: MockDispatcher { event in
                guard let event = event as? SignOutEvent,
                      case .revokeToken(let data, let error, let globalSignOutError) = event.eventType else {
                    XCTFail("Expected SignOutEvent.revokeToken, got \(event)")
                    expectation.fulfill()
                    return
                }

                XCTAssertNil(error)
                XCTAssertNil(globalSignOutError)
                XCTAssertEqual(data, signInData)
                expectation.fulfill()
            },
            environment: Defaults.makeDefaultAuthEnvironment(
                userPoolFactory: identityProviderFactory,
                hostedUIEnvironment: hostedUIEnvironment
            )
        )

        await fulfillment(of: [expectation], timeout: 1)
    }
    
    /// Given: A ShowHostedUISignOut action
    /// When: execute is invoked but fails to create a HostedUI session
    /// Then: A .userCancelled event is dispatched
    func testExecute_withInvalidResult_shouldDispatchUserCancelledEvent() async {
        mockHostedUIResult = .failure(.cancelled)
        let signInData = SignedInData.testData
        
        let action = ShowHostedUISignOut(
            signOutEvent: .testData,
            signInData: signInData
        )

        let expectation = expectation(description: "showHostedUISignOut")
        await action.execute(
            withDispatcher: MockDispatcher { event in
                guard let event = event as? SignOutEvent else {
                    XCTFail("Expected SignOutEvent, got \(event)")
                    expectation.fulfill()
                    return
                }

                XCTAssertEqual(event.eventType, .userCancelled)
                expectation.fulfill()
            },
            environment: Defaults.makeDefaultAuthEnvironment(
                userPoolFactory: identityProviderFactory,
                hostedUIEnvironment: hostedUIEnvironment
            )
        )

        await fulfillment(of: [expectation], timeout: 1)
    }

    /// Given: A ShowHostedUISignOut action
    /// When: execute is invoked but fails to create a HostedUI session with a HostedUIError.signOutURI
    /// Then: A .signOutGlobally event is dispatched with a HosterUIError.configuration error
    func testExecute_withSignOutURIError_shouldThrowConfigurationError() async {
        mockHostedUIResult = .failure(HostedUIError.signOutURI)
        let signInData = SignedInData.testData
        
        let action = ShowHostedUISignOut(
            signOutEvent: .testData,
            signInData: signInData
        )

        let expectation = expectation(description: "showHostedUISignOut")
        await action.execute(
            withDispatcher: MockDispatcher { event in
                guard let event = event as? SignOutEvent,
                      case .signOutGlobally(let data, let hostedUIError) = event.eventType else {
                    XCTFail("Expected SignOutEvent.signOutGlobally, got \(event)")
                    expectation.fulfill()
                    return
                }

                guard let hostedUIError = hostedUIError,
                      case .configuration(let errorDescription, _, let serviceError) = hostedUIError.error else {
                    XCTFail("Expected AuthError.configuration")
                    expectation.fulfill()
                    return
                }

                XCTAssertEqual(errorDescription, "Could not create logout URL")
                XCTAssertEqual(data, signInData)
                XCTAssertNil(serviceError)
                expectation.fulfill()
            },
            environment: Defaults.makeDefaultAuthEnvironment(
                userPoolFactory: identityProviderFactory,
                hostedUIEnvironment: hostedUIEnvironment
            )
        )

        await fulfillment(of: [expectation], timeout: 1)
    }
    
    /// Given: A ShowHostedUISignOut action
    /// When: execute is invoked but fails to create a HostedUI session with a HostedUIError.invalidContext
    /// Then: A .signOutGlobally event is dispatched with a HosterUIError.invalidState error
    func testExecute_withInvalidContext_shouldThrowInvalidStateError() async {
        mockHostedUIResult = .failure(HostedUIError.invalidContext)
        let signInData = SignedInData.testData
        
        let action = ShowHostedUISignOut(
            signOutEvent: .testData,
            signInData: signInData
        )

        let expectation = expectation(description: "showHostedUISignOut")
        await action.execute(
            withDispatcher: MockDispatcher { event in
                guard let event = event as? SignOutEvent,
                      case .signOutGlobally(let data, let hostedUIError) = event.eventType else {
                    XCTFail("Expected SignOutEvent.signOutGlobally, got \(event)")
                    expectation.fulfill()
                    return
                }

                guard let hostedUIError = hostedUIError,
                      case .invalidState(let errorDescription, let recoverySuggestion, let serviceError) = hostedUIError.error else {
                    XCTFail("Expected AuthError.invalidState")
                    expectation.fulfill()
                    return
                }

                XCTAssertEqual(errorDescription, AuthPluginErrorConstants.hostedUIInvalidPresentation.errorDescription)
                XCTAssertEqual(recoverySuggestion, AuthPluginErrorConstants.hostedUIInvalidPresentation.recoverySuggestion)
                XCTAssertEqual(data, signInData)
                XCTAssertNil(serviceError)
                expectation.fulfill()
            },
            environment: Defaults.makeDefaultAuthEnvironment(
                userPoolFactory: identityProviderFactory,
                hostedUIEnvironment: hostedUIEnvironment
            )
        )

        await fulfillment(of: [expectation], timeout: 1)
    }
    
    /// Given: A ShowHostedUISignOut action with an invalid SignOutRedirectURI
    /// When: execute is invoked
    /// Then: A .signOutGlobally event is dispatched with a HosterUIError.configuration error
    func testExecute_withInvalidSignOutURI_shouldThrowConfigurationError() async {
        signOutRedirectURI = "invalidURI"
        let signInData = SignedInData.testData
        
        let action = ShowHostedUISignOut(
            signOutEvent: .testData,
            signInData: signInData
        )

        let expectation = expectation(description: "showHostedUISignOut")
        await action.execute(
            withDispatcher: MockDispatcher { event in
                guard let event = event as? SignOutEvent,
                      case .signOutGlobally(let data, let hostedUIError) = event.eventType else {
                    XCTFail("Expected SignOutEvent.signOutGlobally, got \(event)")
                    expectation.fulfill()
                    return
                }

                guard let hostedUIError = hostedUIError,
                      case .configuration(let errorDescription, _, let serviceError) = hostedUIError.error else {
                    XCTFail("Expected AuthError.configuration")
                    expectation.fulfill()
                    return
                }

                XCTAssertEqual(errorDescription, "Callback URL could not be retrieved")
                XCTAssertEqual(data, signInData)
                XCTAssertNil(serviceError)
                expectation.fulfill()
            },
            environment: Defaults.makeDefaultAuthEnvironment(
                userPoolFactory: identityProviderFactory,
                hostedUIEnvironment: hostedUIEnvironment
            )
        )

        await fulfillment(of: [expectation], timeout: 1)
    }

    /// Given: A ShowHostedUISignOut action
    /// When: execute is invoked with a nil HostedUIEnvironment
    /// Then: A .signOutGlobally event is dispatched with a HosterUIError.configuration error
    func testExecute_withoutHostedUIEnvironment_shouldThrowConfigurationError() async {
        let expectation = expectation(description: "noHostedUIEnvironment")
        let signInData = SignedInData.testData
        let action = ShowHostedUISignOut(
            signOutEvent: .testData,
            signInData: signInData
        )
        await action.execute(
            withDispatcher: MockDispatcher { event in
                guard let event = event as? SignOutEvent,
                      case .signOutGlobally(let data, let hostedUIError) = event.eventType else {
                    XCTFail("Expected SignOutEvent.signOutGlobally, got \(event)")
                    expectation.fulfill()
                    return
                }
                
                guard let hostedUIError = hostedUIError,
                      case .configuration(let errorDescription, _, let serviceError) = hostedUIError.error else {
                    XCTFail("Expected AuthError.configuration")
                    expectation.fulfill()
                    return
                }

                XCTAssertEqual(data, signInData)
                XCTAssertEqual(errorDescription, AuthPluginErrorConstants.configurationError)
                XCTAssertNil(serviceError)
                expectation.fulfill()
            },
            environment: Defaults.makeDefaultAuthEnvironment(
                userPoolFactory: identityProviderFactory,
                hostedUIEnvironment: nil
            )
        )

        await fulfillment(of: [expectation], timeout: 1)
    }
    
    /// Given: A ShowHostedUISignOut action
    /// When: execute is invoked with an invalid environment
    /// Then: A .signOutGlobally event is dispatched with a HosterUIError.configuration error
    func testExecute_withInvalidUserPoolEnvironment_shouldThrowConfigurationError() async {
        let expectation = expectation(description: "invalidUserPoolEnvironment")
        let signInData = SignedInData.testData
        let action = ShowHostedUISignOut(
            signOutEvent: .testData,
            signInData: signInData
        )
        await action.execute(
            withDispatcher: MockDispatcher { event in
                guard let event = event as? SignOutEvent,
                      case .signOutGlobally(let data, let hostedUIError) = event.eventType else {
                    XCTFail("Expected SignOutEvent.signOutGlobally, got \(event)")
                    expectation.fulfill()
                    return
                }
                
                guard let hostedUIError = hostedUIError,
                      case .configuration(let errorDescription, _, let serviceError) = hostedUIError.error else {
                    XCTFail("Expected AuthError.configuration")
                    expectation.fulfill()
                    return
                }

                XCTAssertEqual(data, signInData)
                XCTAssertEqual(errorDescription, AuthPluginErrorConstants.configurationError)
                XCTAssertNil(serviceError)
                expectation.fulfill()
            },
            environment: MockInvalidEnvironment()
        )

        await fulfillment(of: [expectation], timeout: 1)
    }
    
    private func validateDebugInformation(signInData: SignedInData, action: ShowHostedUISignOut) {
        XCTAssertFalse(action.debugDescription.isEmpty)
        guard let signInDataDictionary = action.debugDictionary["signInData"] as? [String: Any] else {
            XCTFail("Expected signInData dictionary")
            return
        }
        XCTAssertEqual(signInDataDictionary.count, signInData.debugDictionary.count)

        for key in signInDataDictionary.keys {
            guard let left = signInDataDictionary[key] as? any Equatable,
                  let right = signInData.debugDictionary[key] as? any Equatable else {
                continue
            }
            XCTAssertTrue(left.isEqual(to: right))
        }
    }
    
    private var hostedUIEnvironment: HostedUIEnvironment {
        BasicHostedUIEnvironment(
            configuration: .init(
                clientId: "clientId",
                oauth: .init(
                    domain: "cognitodomain",
                    scopes: ["name"],
                    signInRedirectURI: "myapp://",
                    signOutRedirectURI: signOutRedirectURI
                )
            ),
            hostedUISessionFactory: {
                MockHostedUISession(result: self.mockHostedUIResult)
            },
            urlSessionFactory: {
                URLSession.shared
            },
            randomStringFactory: {
                MockRandomStringGenerator(
                    mockString: "mockString",
                    mockUUID: "mockUUID"
                )
            }
        )
    }
    
    private func identityProviderFactory() throws -> CognitoUserPoolBehavior {
        return MockIdentityProvider(
            mockInitiateAuthResponse: { _ in
                return InitiateAuthOutput(
                    authenticationResult: .init(
                        accessToken: "accessTokenNew",
                        expiresIn: 100,
                        idToken: "idTokenNew",
                        refreshToken: "refreshTokenNew")
                )
            }
        )
    }
}

private extension Equatable {
    func isEqual(to other: any Equatable) -> Bool {
        guard let other = other as? Self else {
            return false
        }
        return self == other
    }
}
