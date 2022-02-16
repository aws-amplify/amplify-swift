//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest

@testable import AWSCognitoAuthPlugin

class StoreCredentialTests: XCTestCase {

    /// Test is responsible to check the happy path of storing credentials into the store
    ///
    /// - Given: A set of credentials
    /// - When: The store credential action  is executed
    /// - Then:
    ///    - the credentials should be saved into the credential store
    func testStoreCredentials() {
        let mockedData = "mock"
        let testData = CognitoCredentials.testData
        let saveCredentialHandlerInvoked = expectation(description: "saveCredentialHandlerInvoked")

        let mockLegacyCredentialStoreBehavior = MockCredentialStoreBehavior(data: mockedData)
        let legacyCredentialStoreFactory: BasicCredentialStoreEnvironment.CredentialStoreFactory = { service in
            return mockLegacyCredentialStoreBehavior
        }
        let mockAmplifyCredentialStoreBehavior = MockAmplifyCredentialStoreBehavior(
            saveCredentialHandler: { credentials in
                XCTAssertEqual(credentials, testData)
                // Validate the data returned is correct and matches the mocked data.
                saveCredentialHandlerInvoked.fulfill()
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

        let action = StoreCredentials(credentials: testData)
        action.execute(withDispatcher: MockDispatcher { _ in },
                        environment: environment)

        waitForExpectations(timeout: 0.1)
    }

    /// Test is responsible to check if configuration error is correctly caught by the action
    ///
    /// - Given: A set of credentials and an invalid environment
    /// - When: The store credential action  is executed
    /// - Then:
    ///    - The action should throw an error
    func testStoreCredentialsInvalidEnvironment() {
        let expectation = expectation(description: "throwStoreCredentialConfigurationError")

        let expectedError = CredentialStoreError.configuration(
            message: AuthPluginErrorConstants.configurationError)

        let environment = MockInvalidEnvironment()

        let action = StoreCredentials(credentials: .testData)
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

    /// Test is responsible to check if the store credentials handle a known error
    ///
    /// - Given: A set of credentials and an expected error from the Mock
    /// - When: The store credential action is executed
    /// - Then:
    ///    - the action should throw a known error
    func testStoreCredentialsKnownException() {
        let mockedData = "mock"
        let testData = CognitoCredentials.testData
        let expectation = expectation(description: "saveCredentialErrorInvoked")

        let expectedError = CredentialStoreError.securityError(30_534)

        let mockLegacyCredentialStoreBehavior = MockCredentialStoreBehavior(data: mockedData)
        let legacyCredentialStoreFactory: BasicCredentialStoreEnvironment.CredentialStoreFactory = { service in
            return mockLegacyCredentialStoreBehavior
        }
        let mockAmplifyCredentialStoreBehavior = MockAmplifyCredentialStoreBehavior(
            saveCredentialHandler: { credentials in
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

        let action = StoreCredentials(credentials: testData)
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

    /// Test is responsible to check if the store credentials handle an unknown error
    ///
    /// - Given: A set of credentials and an expected unknown error from the Mock
    /// - When: The store credential action is executed
    /// - Then:
    ///    - the action should throw an  unknown error
    func testStoreCredentialsUnknownKnownException() {
        let mockedData = "mock"
        let testData = CognitoCredentials.testData
        let expectation = expectation(description: "saveCredentialErrorInvoked")

        let unknownError = AuthorizationError.invalidIdentityId(message: "")
        let expectedError = CredentialStoreError.unknown("An unknown error occurred", unknownError)

        let mockLegacyCredentialStoreBehavior = MockCredentialStoreBehavior(data: mockedData)
        let legacyCredentialStoreFactory: BasicCredentialStoreEnvironment.CredentialStoreFactory = { service in
            return mockLegacyCredentialStoreBehavior
        }
        let mockAmplifyCredentialStoreBehavior = MockAmplifyCredentialStoreBehavior(
            saveCredentialHandler: { credentials in
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

        let action = StoreCredentials(credentials: testData)
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
