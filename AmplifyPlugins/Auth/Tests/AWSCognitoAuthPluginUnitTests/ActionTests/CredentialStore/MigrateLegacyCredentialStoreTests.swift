//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest

@testable import AWSCognitoAuthPlugin

class MigrateLegacyCredentialStoreTests: XCTestCase {

    typealias AmplifyStoreFactory = BasicCredentialStoreEnvironment.AmplifyAuthCredentialStoreFactory

    /// Test is responsible to check the happy path business logic of migrating the legacy store data.
    ///
    /// - Given: A credential store with legacy data
    /// - When: The migration legacy store action is executed
    /// - Then:
    ///    - the new credential store should get the correct identityId, userPoolTokens and awsCredentials
    func testSaveLegacyCredentials() {
        let mockedData = "mock"
        let saveCredentialHandlerInvoked = expectation(description: "saveCredentialHandlerInvoked")

        let mockLegacyCredentialStoreBehavior = MockCredentialStoreBehavior(data: mockedData)
        let legacyCredentialStoreFactory: BasicCredentialStoreEnvironment.CredentialStoreFactory = { _ in
            return mockLegacyCredentialStoreBehavior
        }
        let mockAmplifyCredentialStoreBehavior = MockAmplifyCredentialStoreBehavior(
            saveCredentialHandler: { codableCredentials in
                guard let credentials = codableCredentials as? AmplifyCredentials,
                      case .userPoolAndIdentityPool(
                        tokens: let tokens,
                        identityID: let identityID,
                        credentials: let awsCredentials) = credentials else {
                    XCTFail("The credentials saved should be of type AmplifyCredentials")
                    return
                }
                // Validate the data returned is correct and matches the mocked data.
                XCTAssertEqual(identityID, mockedData)
                XCTAssertEqual(tokens.refreshToken, mockedData)
                XCTAssertEqual(tokens.accessToken, mockedData)
                XCTAssertEqual(tokens.idToken, mockedData)
                XCTAssertEqual(tokens.expiration, Date.init(timeIntervalSince1970: 0))
                XCTAssertEqual(awsCredentials.sessionKey, mockedData)
                XCTAssertEqual(awsCredentials.secretKey, mockedData)
                XCTAssertEqual(awsCredentials.accessKey, mockedData)
                XCTAssertEqual(awsCredentials.expiration, Date.init(timeIntervalSince1970: 0))

                saveCredentialHandlerInvoked.fulfill()
            }
        )

        let amplifyCredentialStoreFactory: AmplifyStoreFactory = {
            return mockAmplifyCredentialStoreBehavior
        }
        let authConfig = AuthConfiguration.userPoolsAndIdentityPools(
            Defaults.makeDefaultUserPoolConfigData(),
            Defaults.makeIdentityConfigData())

        let credentialStoreEnv = BasicCredentialStoreEnvironment(
            amplifyCredentialStoreFactory: amplifyCredentialStoreFactory,
            legacyCredentialStoreFactory: legacyCredentialStoreFactory)

        let environment = CredentialEnvironment(authConfiguration: authConfig,
                                                credentialStoreEnvironment: credentialStoreEnv)

        let action = MigrateLegacyCredentialStore()
        action.execute(withDispatcher: MockDispatcher { _ in }, environment: environment)

        waitForExpectations(timeout: 0.1)
    }

    /// Test is responsible for making sure that the legacy credential store clearing up is getting called for user pool and identity pool
    ///
    /// - Given: A credential store with legacy data
    /// - When: The migration legacy store action is executed
    /// - Then:
    ///    - The remove all method gets called for both user pool and identity pool
    func testClearLegacyCredentialStore() {
        let migrationCompletionInvoked = expectation(description: "migrationCompletionInvoked")
        migrationCompletionInvoked.expectedFulfillmentCount = 2

        let mockLegacyCredentialStoreBehavior = MockCredentialStoreBehavior(
            data: "mock",
            removeAllHandler: {
                migrationCompletionInvoked.fulfill()
            }
        )
        let legacyCredentialStoreFactory: BasicCredentialStoreEnvironment.CredentialStoreFactory = { _ in
            return mockLegacyCredentialStoreBehavior
        }
        let mockAmplifyCredentialStoreBehavior = MockAmplifyCredentialStoreBehavior()

        let amplifyCredentialStoreFactory: AmplifyStoreFactory = {
            return mockAmplifyCredentialStoreBehavior
        }
        let authConfig = AuthConfiguration.userPoolsAndIdentityPools(
            Defaults.makeDefaultUserPoolConfigData(),
            Defaults.makeIdentityConfigData())

        let credentialStoreEnv = BasicCredentialStoreEnvironment(
            amplifyCredentialStoreFactory: amplifyCredentialStoreFactory,
            legacyCredentialStoreFactory: legacyCredentialStoreFactory)

        let environment = CredentialEnvironment(authConfiguration: authConfig,
                                                credentialStoreEnvironment: credentialStoreEnv)

        let action = MigrateLegacyCredentialStore()
        action.execute(withDispatcher: MockDispatcher { _ in }, environment: environment)

        waitForExpectations(timeout: 0.1)

    }

}
