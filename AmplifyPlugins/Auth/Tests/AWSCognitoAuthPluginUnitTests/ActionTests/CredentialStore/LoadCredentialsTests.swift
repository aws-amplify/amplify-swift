//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest

@testable import AWSCognitoAuthPlugin

class LoadCredentialsTests: XCTestCase {

    /// Test is responsible to check the happy path of retrieving credentials from the store
    ///
    /// - Given: A credential store
    /// - When: The load credential action  is executed
    /// - Then:
    ///    - the credentials should be retrieved from the credential store
    func testLoadCredentials() {
        let mockedData = "mock"
        let testData = AmplifyCredentials.testData
        let loadCredentialHandlerInvoked = expectation(description: "loadCredentialHandlerInvoked")

        let mockLegacyCredentialStoreBehavior = MockCredentialStoreBehavior(data: mockedData)
        let legacyCredentialStoreFactory: BasicCredentialStoreEnvironment.CredentialStoreFactory = { service in
            return mockLegacyCredentialStoreBehavior
        }
        let mockAmplifyCredentialStoreBehavior = MockAmplifyCredentialStoreBehavior(
            getCredentialHandler: {
                return testData
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

        let action = LoadCredentialStore()
        action.execute(withDispatcher: MockDispatcher { event in

            guard let event = event as? CredentialStoreEvent else {
                XCTFail("Expected event to be CredentialStoreEvent")
                return
            }

            if case let .completedOperation(credentials)  = event.eventType {
                XCTAssertNotNil(credentials)
                XCTAssertEqual(credentials, testData)
                loadCredentialHandlerInvoked.fulfill()
            }
        }, environment: environment)

        waitForExpectations(timeout: 0.1)
    }

    /// Test is responsible to check if configuration error is correctly caught by the action
    ///
    /// - Given: An invalid environment
    /// - When: The load credential action  is executed
    /// - Then:
    ///    - The action should throw an error
    func testLoadCredentialsInvalidEnvironment() {
        let expectation = expectation(description: "throwLoadCredentialConfigurationError")

        let expectedError = CredentialStoreError.configuration(
            message: AuthPluginErrorConstants.configurationError)

        let environment = MockInvalidEnvironment()

        let action = LoadCredentialStore()
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

    /// Test is responsible to check if the load credentials handle a known error
    ///
    /// - Given: A credential store and an expected error from the Mock
    /// - When: The load credential action is executed
    /// - Then:
    ///    - the action should throw a known error
    func testLoadCredentialsKnownException() {
        let mockedData = "mock"
        let expectation = expectation(description: "loadCredentialErrorInvoked")

        let expectedError = CredentialStoreError.securityError(30_534)

        let mockLegacyCredentialStoreBehavior = MockCredentialStoreBehavior(data: mockedData)
        let legacyCredentialStoreFactory: BasicCredentialStoreEnvironment.CredentialStoreFactory = { service in
            return mockLegacyCredentialStoreBehavior
        }
        let mockAmplifyCredentialStoreBehavior = MockAmplifyCredentialStoreBehavior(
            getCredentialHandler: {
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

        let action = LoadCredentialStore()
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

    /// Test is responsible to check if the load credentials handle an unknown error
    ///
    /// - Given: A expected unknown error from the Mock
    /// - When: The load credential action is executed
    /// - Then:
    ///    - the action should throw an  unknown error
    func testLoadCredentialsUnknownKnownException() {
        let mockedData = "mock"
        let expectation = expectation(description: "loadCredentialErrorInvoked")

        let unknownError = AuthorizationError.invalidIdentityId(message: "")
        let expectedError = CredentialStoreError.unknown("An unknown error occurred", unknownError)

        let mockLegacyCredentialStoreBehavior = MockCredentialStoreBehavior(data: mockedData)
        let legacyCredentialStoreFactory: BasicCredentialStoreEnvironment.CredentialStoreFactory = { service in
            return mockLegacyCredentialStoreBehavior
        }
        let mockAmplifyCredentialStoreBehavior = MockAmplifyCredentialStoreBehavior(
            getCredentialHandler: {
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

        let action = LoadCredentialStore()
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
