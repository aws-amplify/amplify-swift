//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest

import Amplify
import AWSPluginsCore
@testable import AWSCognitoAuthPlugin

class ConfigureFetchIdentityTests: XCTestCase {
    
    
    func testWithValidIdentity() {
        
        let identityIdExpectation = expectation(description: "fetchedIdentityId")
        let fetchAWSCredentialEventExpectation = expectation(description: "fetchAWSCredential")
        
        let cognitoSessionInput = AWSAuthCognitoSession.testData
        let action = ConfigureFetchIdentity(cognitoSession: cognitoSessionInput)
        
        let environment = AuthEnvironment(userPoolConfigData: nil,
                                          identityPoolConfigData: nil,
                                          authenticationEnvironment: nil,
                                          authorizationEnvironment: nil,
                                          credentialStoreEnvironment: nil)
        
        action.execute(
            withDispatcher: MockDispatcher { event in
                
                if let event = event as? FetchIdentityEvent,
                   case .fetched = event.eventType {
                    identityIdExpectation.fulfill()
                } else if let event = event as? FetchAuthSessionEvent,
                          case let .fetchAWSCredentials(cognitoSession) = event.eventType {
                    XCTAssertEqual(cognitoSession, cognitoSessionInput)
                    fetchAWSCredentialEventExpectation.fulfill()
                }
            },
            environment: environment
        )
        
        waitForExpectations(timeout: 0.1)
    }
    
    func testWithNoIdentityId() {
        
        let expectation = expectation(description: "startFetchingIdentityId")
        
        let cognitoSessionInput = AWSAuthCognitoSession.testData.copySessionByUpdating(identityIdResult: .failure(AuthError.unknown("", nil)))

        let action = ConfigureFetchIdentity(cognitoSession: cognitoSessionInput)

        let environment = AuthEnvironment(userPoolConfigData: nil,
                                          identityPoolConfigData: nil,
                                          authenticationEnvironment: nil,
                                          authorizationEnvironment: nil,
                                          credentialStoreEnvironment: nil)
        
        action.execute(
            withDispatcher: MockDispatcher { event in
                
                guard let event = event as? FetchIdentityEvent else {
                    return
                }
                
                if case let .fetch(cognitoSession) = event.eventType {
                    XCTAssertEqual(cognitoSession, cognitoSessionInput)
                    expectation.fulfill()
                }
            },
            environment: environment
        )
        
        waitForExpectations(timeout: 0.1)
    }
    
}
