//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest

import AWSCognitoIdentity

@testable import AWSCognitoAuthPlugin

class FetchAuthAWSCredentialsTests: XCTestCase {
    
    func testNoEnvironment() {
        
        let expectation = expectation(description: "noAuthorizationEnvironment")
        
        let action = FetchAuthAWSCredentials(cognitoSession: AWSAuthCognitoSession.testData)

        action.execute(
            withDispatcher: MockDispatcher { event in
                
                guard let event = event as? FetchAWSCredentialEvent else {
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
    
    func testInvalidIdentitySuccessfulResponse() {
        
        let expectation = expectation(description: "fetchAWSCredentials")
        let identityProviderFactory: BasicAuthorizationEnvironment.CognitoIdentityFactory = {
            MockIdentity(getCredentialsCallback:  { _, callback in
                callback(.success(GetCredentialsForIdentityOutputResponse()))
            })
        }
        let authorizationEnvironment = BasicAuthorizationEnvironment(identityPoolConfiguration: IdentityPoolConfigurationData.testData,
                                                                     cognitoIdentityFactory: identityProviderFactory)
        
        let action = FetchAuthAWSCredentials(cognitoSession: AWSAuthCognitoSession.testData)

        action.execute(
            withDispatcher: MockDispatcher { event in
                
                guard let event = event as? FetchAWSCredentialEvent else {
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
    
    func testInvalidAWSCredentialSuccessfulResponse() {
        
        let expectation = expectation(description: "fetchAWSCredentials")
        let identityProviderFactory: BasicAuthorizationEnvironment.CognitoIdentityFactory = {
            MockIdentity(getCredentialsCallback:  { _, callback in
                callback(.success(GetCredentialsForIdentityOutputResponse(identityId: "identityId")))
            })
        }
        let authorizationEnvironment = BasicAuthorizationEnvironment(identityPoolConfiguration: IdentityPoolConfigurationData.testData,
                                                                     cognitoIdentityFactory: identityProviderFactory)
        
        let action = FetchAuthAWSCredentials(cognitoSession: AWSAuthCognitoSession.testData)
        
        action.execute(
            withDispatcher: MockDispatcher { event in
                
                guard let event = event as? FetchAWSCredentialEvent else {
                    return
                }
                
                if case let .throwError(error) = event.eventType {
                    XCTAssertNotNil(error)
                    XCTAssertEqual(error, AuthorizationError.invalidAWSCredentials(message: "AWSCredentials are invalid."))
                    expectation.fulfill()
                }
            },
            environment: authorizationEnvironment
        )
        
        waitForExpectations(timeout: 0.1)
    }
    
    func testValidSuccessfulResponse() {
        
        let credentialValidExpectation = expectation(description: "awsCredentialsAreValid")
        let fetchedAuthSessionExpectation = expectation(description: "fetchedAuthSession")
        
        let expectedIdentityId = "newIdentityId"
        let expectedSecretKey = "newSecretKey"
        let expectedSessionToken = "newSessionToken"
        let expectedAccessKey = "newAccessKey"
        
        let identityProviderFactory: BasicAuthorizationEnvironment.CognitoIdentityFactory = {
            MockIdentity(getCredentialsCallback:  { _, callback in
                callback(.success(GetCredentialsForIdentityOutputResponse(
                    credentials: CognitoIdentityClientTypes.Credentials(
                        accessKeyId: expectedAccessKey,
                        expiration: Date(),
                        secretKey: expectedSecretKey,
                        sessionToken: expectedSessionToken),
                    identityId: expectedIdentityId)))
            })
        }
        let authorizationEnvironment = BasicAuthorizationEnvironment(identityPoolConfiguration: IdentityPoolConfigurationData.testData,
                                                                     cognitoIdentityFactory: identityProviderFactory)
        
        let action = FetchAuthAWSCredentials(cognitoSession: AWSAuthCognitoSession.testData)

        action.execute(
            withDispatcher: MockDispatcher { event in
                
                if let event = event as? FetchAWSCredentialEvent,
                   case .fetched = event.eventType {
                    credentialValidExpectation.fulfill()
                } else if let event = event as? FetchAuthSessionEvent,
                          case .fetchedAuthSession = event.eventType {
                    fetchedAuthSessionExpectation.fulfill()
                }
            },
            environment: authorizationEnvironment
        )
        waitForExpectations(timeout: 0.1)
    }
    
    func testFailureResponse() {
        
        let fetchedSessionExpectation = expectation(description: "fetchedSession")
        let expectation = expectation(description: "failureError")
        
        let testError = NSError(domain: "testError", code: 0, userInfo: nil)
        
        let identityProviderFactory: BasicAuthorizationEnvironment.CognitoIdentityFactory = {
            MockIdentity(getCredentialsCallback:  { _, callback in
                callback(.failure(.unknown(testError)))
            })
        }
        let authorizationEnvironment = BasicAuthorizationEnvironment(identityPoolConfiguration: IdentityPoolConfigurationData.testData,
                                                                     cognitoIdentityFactory: identityProviderFactory)
        
        let action = FetchAuthAWSCredentials(cognitoSession: AWSAuthCognitoSession.testData)

        action.execute(
            withDispatcher: MockDispatcher { event in
                
                if let fetchAWSCredentialEvent = event as? FetchAWSCredentialEvent,
                   case let .throwError(error) = fetchAWSCredentialEvent.eventType {
                    XCTAssertNotNil(error)
                    XCTAssertEqual(error, AuthorizationError.service(error: testError))
                    expectation.fulfill()
                } else if let authSessionEvent = event as? FetchAuthSessionEvent,
                          case .fetchedAuthSession = authSessionEvent.eventType {
                    fetchedSessionExpectation.fulfill()
                }
            },
            environment: authorizationEnvironment
        )
        waitForExpectations(timeout: 0.1)
    }
    
}
