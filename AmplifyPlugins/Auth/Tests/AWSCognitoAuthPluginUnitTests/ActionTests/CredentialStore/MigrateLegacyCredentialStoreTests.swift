//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
import Amplify
@testable import AWSCognitoAuthPlugin

class MigrateLegacyCredentialStoreTests: XCTestCase {

    typealias AmplifyStoreFactory = BasicCredentialStoreEnvironment.AmplifyAuthCredentialStoreFactory

    /// Test is responsible to check the happy path business logic of migrating the legacy store data.
    ///
    /// - Given: A credential store with legacy data
    /// - When: The migration legacy store action is executed
    /// - Then:
    ///    - the new credential store should get the correct identityId, userPoolTokens and awsCredentials
    func testSaveLegacyCredentials() async {
        let mockedData = "mock"
        let saveCredentialHandlerInvoked = expectation(description: "saveCredentialHandlerInvoked")

        let mockLegacyKeychainStoreBehavior = MockKeychainStoreBehavior(data: mockedData)
        let legacyKeychainStoreFactory: BasicCredentialStoreEnvironment.KeychainStoreFactory = { _ in
            return mockLegacyKeychainStoreBehavior
        }
        let mockAmplifyCredentialStoreBehavior = MockAmplifyCredentialStoreBehavior(
            saveCredentialHandler: { codableCredentials in
                guard let credentials = codableCredentials as? AmplifyCredentials,
                      case .userPoolAndIdentityPool(
                        signedInData: let signedInData,
                        identityID: let identityID,
                        credentials: let awsCredentials) = credentials else {
                    XCTFail("The credentials saved should be of type AmplifyCredentials")
                    return
                }
                let tokens = signedInData.cognitoUserPoolTokens
                // Validate the data returned is correct and matches the mocked data.
                XCTAssertEqual(identityID, mockedData)
                XCTAssertEqual(tokens.refreshToken, mockedData)
                XCTAssertEqual(tokens.accessToken, mockedData)
                XCTAssertEqual(tokens.idToken, mockedData)
                XCTAssertEqual(tokens.expiration, Date.init(timeIntervalSince1970: 0))
                XCTAssertEqual(awsCredentials.sessionToken, mockedData)
                XCTAssertEqual(awsCredentials.secretAccessKey, mockedData)
                XCTAssertEqual(awsCredentials.accessKeyId, mockedData)
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
            legacyKeychainStoreFactory: legacyKeychainStoreFactory)

        let environment = CredentialEnvironment(
            authConfiguration: authConfig,
            credentialStoreEnvironment: credentialStoreEnv,
            logger: Amplify.Logging.logger(forCategory: "awsCognitoAuthPluginTest"))

        let action = MigrateLegacyCredentialStore()
        await action.execute(withDispatcher: MockDispatcher { _ in }, environment: environment)


        await fulfillment(
            of: [saveCredentialHandlerInvoked],
            timeout: 0.1
        )
    }

    /// Test is responsible for making sure that the legacy credential store clearing up is getting called for user pool and identity pool
    ///
    /// - Given: A credential store with legacy data
    /// - When: The migration legacy store action is executed
    /// - Then:
    ///    - The remove all method gets called for both user pool and identity pool
    func testClearLegacyCredentialStore() async {
        let migrationCompletionInvoked = expectation(description: "migrationCompletionInvoked")
        migrationCompletionInvoked.expectedFulfillmentCount = 3

        let mockLegacyKeychainStoreBehavior = MockKeychainStoreBehavior(
            data: "mock",
            removeAllHandler: {
                migrationCompletionInvoked.fulfill()
            }
        )
        let legacyKeychainStoreFactory: BasicCredentialStoreEnvironment.KeychainStoreFactory = { _ in
            return mockLegacyKeychainStoreBehavior
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
            legacyKeychainStoreFactory: legacyKeychainStoreFactory)

        let environment = CredentialEnvironment(
            authConfiguration: authConfig,
            credentialStoreEnvironment: credentialStoreEnv,
            logger: Amplify.Logging.logger(forCategory: "awsCognitoAuthPluginTest"))

        let action = MigrateLegacyCredentialStore()
        await action.execute(withDispatcher: MockDispatcher { _ in }, environment: environment)

        await fulfillment(
            of: [migrationCompletionInvoked],
    
            timeout: 0.1
        )
    }

    /// - Given: A credential store with an invalid environment
    /// - When: The migration legacy store action is executed
    /// - Then: An error event of type configuration is dispatched
    func testExecute_withInvalidEnvironment_shouldDispatchError() async {
        let expectation = expectation(description: "noEnvironment")
        let action = MigrateLegacyCredentialStore()
        await action.execute(
            withDispatcher: MockDispatcher { event in
                guard let event = event as? CredentialStoreEvent,
                      case let .throwError(error) = event.eventType else {
                    XCTFail("Expected failure due to no CredentialEnvironment")
                    expectation.fulfill()
                    return
                }
                XCTAssertEqual(error, .configuration(message: AuthPluginErrorConstants.configurationError))
                expectation.fulfill()
            },
            environment: MockInvalidEnvironment()
        )
        await fulfillment(of: [expectation], timeout: 1)
    }
    
    /// - Given: A credential store with an environment that only has identity pool
    /// - When: The migration legacy store action is executed
    /// - Then: 
    ///     - A .loadCredentialStore event with type .amplifyCredentials is dispatched
    ///     - An .identityPoolOnly credential is saved
    func testExecute_withoutUserPool_andWithoutLoginsTokens_shouldDispatchLoadEvent() async {
        let expectation = expectation(description: "noUserPoolTokens")
        let action = MigrateLegacyCredentialStore()
        await action.execute(
            withDispatcher: MockDispatcher { event in
                guard let event = event as? CredentialStoreEvent,
                      case .loadCredentialStore(let type) = event.eventType else {
                    XCTFail("Expected .loadCredentialStore")
                    expectation.fulfill()
                    return
                }
                XCTAssertEqual(type, .amplifyCredentials)
                expectation.fulfill()
            },
            environment: CredentialEnvironment(
                authConfiguration: .identityPools(.testData),
                credentialStoreEnvironment: BasicCredentialStoreEnvironment(
                    amplifyCredentialStoreFactory: {
                        MockAmplifyCredentialStoreBehavior(
                            saveCredentialHandler: { codableCredentials in
                                guard let amplifyCredentials = codableCredentials as? AmplifyCredentials,
                                      case .identityPoolOnly(_, let credentials) = amplifyCredentials else {
                                    XCTFail("Expected .identityPoolOnly")
                                    return
                                }
                                XCTAssertFalse(credentials.sessionToken.isEmpty)
                            }
                        )
                    },
                    legacyKeychainStoreFactory: { _ in
                        MockKeychainStoreBehavior(data: "hostedUI")
                    }),
                logger: MigrateLegacyCredentialStore.log
            )
        )
        await fulfillment(of: [expectation], timeout: 1)
    }
    
    /// - Given: A credential store with an environment that only has identity pool
    /// - When: The migration legacy store action is executed
    ///     - A .loadCredentialStore event with type .amplifyCredentials is dispatched
    ///     - An .identityPoolWithFederation credential is saved
    func testExecute_withoutUserPool_andWithLoginsTokens_shouldDispatchLoadEvent() async {
        let expectation = expectation(description: "noUserPoolTokens")
        let action = MigrateLegacyCredentialStore()
        await action.execute(
            withDispatcher: MockDispatcher { event in
                guard let event = event as? CredentialStoreEvent,
                      case .loadCredentialStore(let type) = event.eventType else {
                    XCTFail("Expected .loadCredentialStore")
                    expectation.fulfill()
                    return
                }
                XCTAssertEqual(type, .amplifyCredentials)
                expectation.fulfill()
            },
            environment: CredentialEnvironment(
                authConfiguration: .identityPools(.testData),
                credentialStoreEnvironment: BasicCredentialStoreEnvironment(
                    amplifyCredentialStoreFactory: {
                        MockAmplifyCredentialStoreBehavior(
                            saveCredentialHandler: { codableCredentials in
                                guard let amplifyCredentials = codableCredentials as? AmplifyCredentials,
                                      case .identityPoolWithFederation(let token, _, _) = amplifyCredentials else {
                                    XCTFail("Expected .identityPoolWithFederation")
                                    return
                                }

                                XCTAssertEqual(token.token, "token")
                                XCTAssertEqual(token.provider.userPoolProviderName, "provider")
                            }
                        )
                    },
                    legacyKeychainStoreFactory: { _ in
                        let data = try! JSONEncoder().encode([
                            "provider": "token"
                        ])
                        return MockKeychainStoreBehavior(
                            data: String(decoding: data, as: UTF8.self)
                        )
                    }),
                logger: action.log
            )
        )
        await fulfillment(of: [expectation], timeout: 1)
    }
}
