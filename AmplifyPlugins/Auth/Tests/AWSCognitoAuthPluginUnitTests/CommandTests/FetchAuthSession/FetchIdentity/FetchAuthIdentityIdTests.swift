//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest

import AWSCognitoIdentity

@testable import AWSCognitoAuthPlugin

class FetchAuthIdentityIdTests: XCTestCase {
    
    func testNoEnvironment() {
        
        let expectation = expectation(description: "noIdentityEnvironment")
        
        let action = FetchAuthIdentityId(cognitoSession: AWSAuthCognitoSession.testData)
        
        action.execute(
            withDispatcher: MockDispatcher { event in
                
                guard let event = event as? FetchIdentityEvent else {
                    return
                }
                
                if case let .throwError(error) = event.eventType {
                    XCTAssertNotNil(error)
                    XCTAssertEqual(error, AuthorizationError.configuration(message: AuthPluginErrorConstants.configurationError))
                    expectation.fulfill()
                }
            },
            environment: MockInvalidEnvironment()
        )
        
        waitForExpectations(timeout: 0.1)
    }
    
    func testInvalidSuccessfulResponse() {
        
        let expectation = expectation(description: "fetchIdentity")
        let identityProviderFactory: BasicAuthorizationEnvironment.CognitoIdentityFactory = {
            MockIdentity { _, callback in
                callback(.success(GetIdOutputResponse()))
            }
        }
        let authorizationEnvironment = BasicAuthorizationEnvironment(identityPoolConfiguration: IdentityPoolConfigurationData.testData,
                                                                     cognitoIdentityFactory: identityProviderFactory)
        
        let action = FetchAuthIdentityId(cognitoSession: AWSAuthCognitoSession.testData)
        
        action.execute(
            withDispatcher: MockDispatcher { event in
                
                guard let event = event as? FetchIdentityEvent else {
                    return
                }
                
                if case let .throwError(error) = event.eventType {
                    XCTAssertNotNil(error)
                    XCTAssertEqual(error, AuthorizationError.invalidIdentityId(message: "IdentityId is invalid."))
                    expectation.fulfill()
                }
            },
            environment: authorizationEnvironment
        )
        
        waitForExpectations(timeout: 0.1)
    }
    
    func testValidSuccessfulResponse() {
        
        let fetchIdentityExpectation = expectation(description: "fetchIdentityEvent")
        let fetchAWSCredentialExpectation = expectation(description: "fetchAWSCredential")
        
        let updatedIdentityId = "updatedIdentityId"
        
        let identityProviderFactory: BasicAuthorizationEnvironment.CognitoIdentityFactory = {
            MockIdentity { _, callback in
                callback(.success(GetIdOutputResponse(identityId: updatedIdentityId)))
            }
        }
        let authorizationEnvironment = BasicAuthorizationEnvironment(identityPoolConfiguration: IdentityPoolConfigurationData.testData,
                                                                     cognitoIdentityFactory: identityProviderFactory)
        
        let action = FetchAuthIdentityId(cognitoSession: AWSAuthCognitoSession.testData)
        
        action.execute(
            withDispatcher: MockDispatcher { event in
                
                if let identityEvent = event as? FetchIdentityEvent,
                   case .fetched = identityEvent.eventType {
                    fetchIdentityExpectation.fulfill()
                } else if let authSessionEvent = event as? FetchAuthSessionEvent,
                          case let .fetchAWSCredentials(credentials) = authSessionEvent.eventType {
                    XCTAssertNotNil(credentials)
                    fetchAWSCredentialExpectation.fulfill()
                }
            },
            environment: authorizationEnvironment
        )
        waitForExpectations(timeout: 0.1)
    }
    
    func testFailureResponse() {
        
        let fetchAWSCredentialExpectation = expectation(description: "fetchAWSCredential")
        let expectation = expectation(description: "failureError")
        
        let testError = NSError(domain: "testError", code: 0, userInfo: nil)
        
        let identityProviderFactory: BasicAuthorizationEnvironment.CognitoIdentityFactory = {
            MockIdentity(getIdCallback:  { _, callback in
                callback(.failure(.unknown(testError)))
            })
        }
        
        let authorizationEnvironment = BasicAuthorizationEnvironment(identityPoolConfiguration: IdentityPoolConfigurationData.testData,
                                                                     cognitoIdentityFactory: identityProviderFactory)
        
        let action = FetchAuthIdentityId(cognitoSession: AWSAuthCognitoSession.testData)
        
        action.execute(
            withDispatcher: MockDispatcher { event in
                
                if let fetchIdentityEvent = event as? FetchIdentityEvent,
                   case let .throwError(error) = fetchIdentityEvent.eventType {
                    XCTAssertNotNil(error)
                    XCTAssertEqual(error, AuthorizationError.service(error: testError))
                    expectation.fulfill()
                } else if let authSessionEvent = event as? FetchAuthSessionEvent,
                          case let .fetchAWSCredentials(cognitoSession) = authSessionEvent.eventType {
                    XCTAssertNotNil(cognitoSession)
                    fetchAWSCredentialExpectation.fulfill()
                }
            },
            environment: authorizationEnvironment
        )
        waitForExpectations(timeout: 0.1)
    }
    
}
