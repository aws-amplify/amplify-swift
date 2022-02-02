//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest

@testable import AWSCognitoAuthPlugin

class InitializeFetchAuthSessionTests: XCTestCase {
    
    func testInitializeUserPoolTokens() {
        let mockedData = "mock"
        let expectation = expectation(description: "initializeUserPool")
        
        let mockLegacyCredentialStoreBehavior = MockCredentialStoreBehavior(data: mockedData)
        let legacyCredentialStoreFactory: BasicCredentialStoreEnvironment.CredentialStoreFactory = { service in
            return mockLegacyCredentialStoreBehavior
        }
        
        let mockCredentialStoreBehavior = MockAmplifyCredentialStoreBehavior(getCredentialHandler: {
            return CognitoCredentials.testData
        })
        
        let amplifyCredentialStoreFactory: BasicCredentialStoreEnvironment.AmplifyAuthCredentialStoreFactory = {
            return mockCredentialStoreBehavior
        }
        
        let credentialStoreEnv = BasicCredentialStoreEnvironment(amplifyCredentialStoreFactory: amplifyCredentialStoreFactory,
                                                                 legacyCredentialStoreFactory: legacyCredentialStoreFactory)
        
        let action = InitializeFetchAuthSession()
        
        let environment = AuthEnvironment(
            userPoolConfigData: nil,
            identityPoolConfigData: nil,
            authenticationEnvironment: nil,
            authorizationEnvironment: nil,
            credentialStoreEnvironment: credentialStoreEnv)
        
        action.execute(
            withDispatcher: MockDispatcher { event in
                
                guard let event = event as? FetchAuthSessionEvent else {
                    XCTFail("Expected event to be FetchAuthSessionEvent")
                    return
                }
                
                if case let .fetchUserPoolTokens(cognitoCredentials)  = event.eventType {
                    XCTAssertNotNil(cognitoCredentials)
                    expectation.fulfill()
                }
                
            },
            environment: environment
        )
        
        waitForExpectations(timeout: 0.1)
    }
    
    func testInitializeIdentityPoolTokens() {
        let mockedData = "mock"
        let expectation = expectation(description: "initializeIdentity")
        
        let mockLegacyCredentialStoreBehavior = MockCredentialStoreBehavior(data: mockedData)
        let legacyCredentialStoreFactory: BasicCredentialStoreEnvironment.CredentialStoreFactory = { service in
            return mockLegacyCredentialStoreBehavior
        }
        
        let mockCredentialStoreBehavior = MockAmplifyCredentialStoreBehavior(getCredentialHandler: {
            return CognitoCredentials(userPoolTokens: nil, identityId: "", awsCredential: nil)
        })
        
        let amplifyCredentialStoreFactory: BasicCredentialStoreEnvironment.AmplifyAuthCredentialStoreFactory = {
            return mockCredentialStoreBehavior
        }
        
        let credentialStoreEnv = BasicCredentialStoreEnvironment(amplifyCredentialStoreFactory: amplifyCredentialStoreFactory,
                                                                 legacyCredentialStoreFactory: legacyCredentialStoreFactory)
        
        let action = InitializeFetchAuthSession()
        
        let environment = AuthEnvironment(
            userPoolConfigData: nil,
            identityPoolConfigData: nil,
            authenticationEnvironment: nil,
            authorizationEnvironment: nil,
            credentialStoreEnvironment: credentialStoreEnv)
        
        action.execute(
            withDispatcher: MockDispatcher { event in
                
                guard let event = event as? FetchAuthSessionEvent else {
                    XCTFail("Expected event to be FetchAuthSessionEvent")
                    return
                }
                
                if case let .fetchIdentity(cognitoCredentials)  = event.eventType {
                    XCTAssertNotNil(cognitoCredentials)
                    expectation.fulfill()
                }
                
            },
            environment: environment
        )
        
        waitForExpectations(timeout: 0.1)
    }
}
