//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest

@testable import AWSCognitoAuthPlugin

class ClearCredentialsTests: XCTestCase {

    /// Test is responsible to check if the clear credentials action invokes the store correctly
    ///
    /// - Given: A set of credentials
    /// - When: The clear credential action  is executed
    /// - Then:
    ///    - the credentials should be cleared
    func testClearCredentials() {
        let mockedData = "mock"
        let expectation = expectation(description: "clearCredentialHandlerInvoked")

        let mockLegacyCredentialStoreBehavior = MockCredentialStoreBehavior(data: mockedData)
        let legacyCredentialStoreFactory: BasicCredentialStoreEnvironment.CredentialStoreFactory = { service in
            return mockLegacyCredentialStoreBehavior
        }
        let mockAmplifyCredentialStoreBehavior = MockAmplifyCredentialStoreBehavior(
            clearCredentialHandler: {
                expectation.fulfill()
            }
        )

        let amplifyCredentialStoreFactory: BasicCredentialStoreEnvironment.AmplifyAuthCredentialStoreFactory = {
            return mockAmplifyCredentialStoreBehavior
        }
        let authConfig = AuthConfiguration.userPoolsAndIdentityPools(Defaults.makeDefaultUserPoolConfigData(),
                                                                     Defaults.makeIdentityConfigData())

        let credentialStoreEnv = BasicCredentialStoreEnvironment(amplifyCredentialStoreFactory: amplifyCredentialStoreFactory,
                                                                 legacyCredentialStoreFactory: legacyCredentialStoreFactory)

        let environment = CredentialEnvironment(authConfiguration: authConfig, credentialStoreEnvironment: credentialStoreEnv)

        let action = ClearCredentialStore()
        action.execute(withDispatcher: MockDispatcher { _ in },
                        environment: environment)

        waitForExpectations(timeout: 0.1)
    }
    
    /// Test is responsible to check if configuration error is correctly caught by the action
    ///
    /// - Given: A set of credentials and an invalid environment
    /// - When: The clear credential action  is executed
    /// - Then:
    ///    - The action should throw an error
    func testClearCredentialsInvalidEnvironment() {
        let expectation = expectation(description: "throwClearCredentialConfigurationError")
        
        let expectedError = CredentialStoreError.configuration(
            message: AuthPluginErrorConstants.configurationError)

        let environment = MockInvalidEnvironment()

        let action = ClearCredentialStore()
        action.execute(withDispatcher: MockDispatcher { event in
            
            guard let event = event as? CredentialStoreEvent else {
                XCTFail("Expected event to be CredentialStoreEvent")
                return
            }
            
            if case let .throwError(error)  = event.eventType {
                XCTAssertNotNil(error)
                XCTAssertEqual(error, expectedError)
                expectation.fulfill()
            }
        }, environment: environment)

        waitForExpectations(timeout: 0.1)
    }
    
    /// Test is responsible to check if the clear credentials handle a known error
    ///
    /// - Given: A set of credentials and an expected error from the Mock
    /// - When: The clear credential action is executed
    /// - Then:
    ///    - the action should throw a known error
    func testClearCredentialsKnownException() {
        let mockedData = "mock"
        let expectation = expectation(description: "clearCredentialErrorInvoked")
        
        let expectedError = CredentialStoreError.securityError(30534)

        let mockLegacyCredentialStoreBehavior = MockCredentialStoreBehavior(data: mockedData)
        let legacyCredentialStoreFactory: BasicCredentialStoreEnvironment.CredentialStoreFactory = { service in
            return mockLegacyCredentialStoreBehavior
        }
        let mockAmplifyCredentialStoreBehavior = MockAmplifyCredentialStoreBehavior(
            clearCredentialHandler: {
                throw expectedError
            }
        )

        let amplifyCredentialStoreFactory: BasicCredentialStoreEnvironment.AmplifyAuthCredentialStoreFactory = {
            return mockAmplifyCredentialStoreBehavior
        }
        let authConfig = AuthConfiguration.userPoolsAndIdentityPools(Defaults.makeDefaultUserPoolConfigData(),
                                                                     Defaults.makeIdentityConfigData())

        let credentialStoreEnv = BasicCredentialStoreEnvironment(amplifyCredentialStoreFactory: amplifyCredentialStoreFactory,
                                                                 legacyCredentialStoreFactory: legacyCredentialStoreFactory)

        let environment = CredentialEnvironment(authConfiguration: authConfig, credentialStoreEnvironment: credentialStoreEnv)

        let action = ClearCredentialStore()
        action.execute(withDispatcher: MockDispatcher { event in
            
            guard let event = event as? CredentialStoreEvent else {
                XCTFail("Expected event to be CredentialStoreEvent")
                return
            }
            
            if case let .throwError(error)  = event.eventType {
                XCTAssertNotNil(error)
                XCTAssertEqual(error, expectedError)
                expectation.fulfill()
            }
        }, environment: environment)

        waitForExpectations(timeout: 0.1)
    }
    
    /// Test is responsible to check if the clear credentials handle an unknown error
    ///
    /// - Given: A set of credentials and an expected unknown error from the Mock
    /// - When: The clear credential action is executed
    /// - Then:
    ///    - the action should throw an  unknown error
    func testClearCredentialsUnknownKnownException() {
        let mockedData = "mock"
        let expectation = expectation(description: "clearCredentialErrorInvoked")
        
        let unknownError = AuthorizationError.invalidIdentityId(message: "")
        let expectedError = CredentialStoreError.unknown("An unknown error occurred", unknownError)

        let mockLegacyCredentialStoreBehavior = MockCredentialStoreBehavior(data: mockedData)
        let legacyCredentialStoreFactory: BasicCredentialStoreEnvironment.CredentialStoreFactory = { service in
            return mockLegacyCredentialStoreBehavior
        }
        let mockAmplifyCredentialStoreBehavior = MockAmplifyCredentialStoreBehavior(
            clearCredentialHandler: {
                throw unknownError
            }
        )

        let amplifyCredentialStoreFactory: BasicCredentialStoreEnvironment.AmplifyAuthCredentialStoreFactory = {
            return mockAmplifyCredentialStoreBehavior
        }
        let authConfig = AuthConfiguration.userPoolsAndIdentityPools(Defaults.makeDefaultUserPoolConfigData(),
                                                                     Defaults.makeIdentityConfigData())

        let credentialStoreEnv = BasicCredentialStoreEnvironment(amplifyCredentialStoreFactory: amplifyCredentialStoreFactory,
                                                                 legacyCredentialStoreFactory: legacyCredentialStoreFactory)

        let environment = CredentialEnvironment(authConfiguration: authConfig, credentialStoreEnvironment: credentialStoreEnv)

        let action = ClearCredentialStore()
        action.execute(withDispatcher: MockDispatcher { event in
            
            guard let event = event as? CredentialStoreEvent else {
                XCTFail("Expected event to be CredentialStoreEvent")
                return
            }
            
            if case let .throwError(error)  = event.eventType {
                XCTAssertNotNil(error)
                XCTAssertEqual(error, expectedError)
                expectation.fulfill()
            }
        }, environment: environment)

        waitForExpectations(timeout: 0.1)
    }

}
