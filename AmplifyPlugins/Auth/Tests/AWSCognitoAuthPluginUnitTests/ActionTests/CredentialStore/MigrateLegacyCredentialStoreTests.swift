//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import AWSPluginsCore
import Security
import XCTest
@testable import AWSCognitoAuthPlugin
@testable import InternalAWSCognitoAuth

// `@unchecked Sendable`: `XCTestCase` is not `Sendable`, but the test body is captured by the
// `@Sendable` closures the API now takes. XCTest runs one test at a time.
class MigrateLegacyCredentialStoreTests: XCTestCase, @unchecked Sendable {

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
                          credentials: let awsCredentials
                      ) = credentials else {
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
            Defaults.makeIdentityConfigData()
        )

        let credentialStoreEnv = BasicCredentialStoreEnvironment(
            amplifyCredentialStoreFactory: amplifyCredentialStoreFactory,
            legacyKeychainStoreFactory: legacyKeychainStoreFactory
        )

        let environment = CredentialEnvironment(
            authConfiguration: authConfig,
            credentialStoreEnvironment: credentialStoreEnv,
            logger: AmplifyEngineLogRouter(scope: .category("awsCognitoAuthPluginTest"))
        )

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
            Defaults.makeIdentityConfigData()
        )

        let credentialStoreEnv = BasicCredentialStoreEnvironment(
            amplifyCredentialStoreFactory: amplifyCredentialStoreFactory,
            legacyKeychainStoreFactory: legacyKeychainStoreFactory
        )

        let environment = CredentialEnvironment(
            authConfiguration: authConfig,
            credentialStoreEnvironment: credentialStoreEnv,
            logger: AmplifyEngineLogRouter(scope: .category("awsCognitoAuthPluginTest"))
        )

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
                    }
                ),
                logger: AmplifyEngineLogRouter(scope: .categoryNamespace("Authentication", "MigrateLegacyCredentialStore"))
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
                    }
                ),
                logger: AmplifyEngineLogRouter(scope: .categoryNamespace("Authentication", "MigrateLegacyCredentialStore"))
            )
        )
        await fulfillment(of: [expectation], timeout: 1)
    }

    /// Test that a legacy value which exists but cannot be read does not cost the user their legacy credentials
    ///
    /// - Given: A legacy store in which every value exists, but one read fails with a keychain error
    ///   (for example `errSecInteractionNotAllowed` while the device is locked). Each case fails a read
    ///   on a different path: the current user (device details and user pool tokens), the ASF device id,
    ///   the refresh token, the identity pool access key, and the federated logins map
    /// - When:
    ///    - The migration legacy store action is executed
    /// - Then:
    ///    - None of the legacy stores are removed, so the migration can be retried on a later launch
    ///    - No partially migrated credentials or device details are saved
    ///    - A .loadCredentialStore event with type .amplifyCredentials is dispatched
    ///
    func testExecute_whenLegacyReadFailsWithKeychainError_shouldKeepLegacyStores() async {
        let failingKeySuffixes = [
            ".currentUser",
            ".asf.device.id",
            ".refreshToken",
            "accessKey",
            "loginsMap"
        ]
        for suffix in failingKeySuffixes {
            let result = await runMigration(
                legacyKeychainStore: MockKeychainStoreBehavior(
                    data: "mock",
                    readErrorForKey: { key in
                        key.hasSuffix(suffix) ? EngineCredentialStoreError.securityError(errSecInteractionNotAllowed) : nil
                    }
                )
            )
            XCTAssertEqual(result.removeAllCount, 0, "Legacy stores were removed when \(suffix) was unreadable")
            XCTAssertEqual(result.savedCredentialCount, 0, "Credentials were saved when \(suffix) was unreadable")
            XCTAssertEqual(result.savedDeviceCount, 0, "Device details were saved when \(suffix) was unreadable")
            XCTAssertEqual(result.loadEventCount, 1, "No load event when \(suffix) was unreadable")
        }
    }

    /// Test that the legacy stores are not removed when the migrated credentials cannot be written forward
    ///
    /// - Given: A legacy store in which every value can be read
    /// - When:
    ///    - The migration legacy store action is executed and saving the migrated credentials fails
    /// - Then:
    ///    - None of the legacy stores are removed
    ///    - The save error is dispatched, once, and nothing else is
    ///
    /// The action calls the stores and the dispatcher before `execute` returns and starts no task, so the
    /// test checks what was recorded once it returns. It does not wait on an inverted expectation: such a
    /// wait can only end by timing out, and if XCTest has not finished it about 15 s after the timeout,
    /// XCTest aborts the whole run ("A stall was detected while waiting on expectations").
    ///
    func testExecute_whenSavingMigratedCredentialsFails_shouldKeepLegacyStores() async {
        let removeAllCount = TestBox(0)
        let dispatchedEvents = TestBox<[CredentialStoreEvent.EventType]>([])

        let saveError = EngineCredentialStoreError.securityError(errSecInteractionNotAllowed)
        let environment = makeEnvironment(
            legacyKeychainStore: MockKeychainStoreBehavior(
                data: "mock",
                removeAllHandler: { removeAllCount.with { $0 += 1 } }
            ),
            amplifyCredentialStore: MockAmplifyCredentialStoreBehavior(
                saveCredentialHandler: { _ in throw saveError }
            )
        )

        let action = MigrateLegacyCredentialStore()
        await action.execute(
            withDispatcher: MockDispatcher { event in
                guard let event = event as? CredentialStoreEvent else {
                    XCTFail("Expected a CredentialStoreEvent, got \(event)")
                    return
                }
                dispatchedEvents.with { $0.append(event.eventType) }
            },
            environment: environment
        )

        XCTAssertEqual(removeAllCount.get(), 0, "Legacy stores were removed although the save failed")
        XCTAssertEqual(dispatchedEvents.get(), [.throwError(saveError)])
    }

    /// Test that incomplete legacy data, which can never be migrated, is still cleaned up as before
    ///
    /// - Given: A legacy store in which the refresh token item does not exist
    /// - When:
    ///    - The migration legacy store action is executed
    /// - Then:
    ///    - The user pool, identity pool and mobile client legacy stores are each removed once
    ///
    func testExecute_whenLegacyItemIsMissing_shouldClearLegacyStores() async {
        let removeAllInvoked = expectation(description: "removeAllInvoked")
        removeAllInvoked.expectedFulfillmentCount = 3

        let environment = makeEnvironment(
            legacyKeychainStore: MockKeychainStoreBehavior(
                data: "mock",
                removeAllHandler: { removeAllInvoked.fulfill() },
                readErrorForKey: { key in
                    key.hasSuffix(".refreshToken") ? EngineCredentialStoreError.itemNotFound : nil
                }
            ),
            amplifyCredentialStore: MockAmplifyCredentialStoreBehavior()
        )

        let action = MigrateLegacyCredentialStore()
        await action.execute(withDispatcher: MockDispatcher { _ in }, environment: environment)

        await fulfillment(of: [removeAllInvoked], timeout: 0.1)
    }

    private func makeEnvironment(
        legacyKeychainStore: MockKeychainStoreBehavior,
        amplifyCredentialStore: MockAmplifyCredentialStoreBehavior
    ) -> CredentialEnvironment {
        CredentialEnvironment(
            authConfiguration: .userPoolsAndIdentityPools(
                Defaults.makeDefaultUserPoolConfigData(),
                Defaults.makeIdentityConfigData()
            ),
            credentialStoreEnvironment: BasicCredentialStoreEnvironment(
                amplifyCredentialStoreFactory: { amplifyCredentialStore },
                legacyKeychainStoreFactory: { _ in legacyKeychainStore }
            ),
            logger: AmplifyEngineLogRouter(scope: .category("awsCognitoAuthPluginTest"))
        )
    }
}

// MARK: - Superseded and unreadable stores

extension MigrateLegacyCredentialStoreTests {

    /// Test that legacy data never replaces a session the new credential store already holds
    ///
    /// - Given: A legacy store in which every value can be read, and a new credential store that already
    ///   holds a session (for example one signed in after an earlier launch could not read the legacy store)
    /// - When:
    ///    - The migration legacy store action is executed
    /// - Then:
    ///    - Neither the legacy credentials nor the legacy device details are written over the new session
    ///    - The user pool, identity pool and mobile client legacy stores are each removed once
    ///    - A .loadCredentialStore event with type .amplifyCredentials is dispatched
    ///
    func testExecute_whenNewStoreAlreadyHasSession_shouldNotOverwriteItAndShouldClearLegacyStores() async {
        let result = await runMigration(
            legacyKeychainStore: MockKeychainStoreBehavior(data: "mock"),
            existingCredentials: { AmplifyCredentials.testData }
        )
        XCTAssertEqual(result.savedCredentialCount, 0)
        XCTAssertEqual(result.savedDeviceCount, 0)
        XCTAssertEqual(result.removeAllCount, 3)
        XCTAssertEqual(result.loadEventCount, 1)
    }

    /// Test that unreadable legacy data is discarded rather than kept once the new store holds a session
    ///
    /// - Given: A legacy store whose refresh token read fails with a keychain error, and a new credential
    ///   store that already holds a session
    /// - When:
    ///    - The migration legacy store action is executed
    /// - Then:
    ///    - Nothing is saved, and the legacy stores are each removed once, so they can never be written
    ///      over the newer session on a later launch
    ///
    func testExecute_whenLegacyReadFailsAndNewStoreHasSession_shouldClearLegacyStores() async {
        let result = await runMigration(
            legacyKeychainStore: MockKeychainStoreBehavior(
                data: "mock",
                readErrorForKey: { key in
                    key.hasSuffix(".refreshToken") ? EngineCredentialStoreError.securityError(errSecInteractionNotAllowed) : nil
                }
            ),
            existingCredentials: { AmplifyCredentials.testData }
        )
        XCTAssertEqual(result.savedCredentialCount, 0)
        XCTAssertEqual(result.savedDeviceCount, 0)
        XCTAssertEqual(result.removeAllCount, 3)
        XCTAssertEqual(result.loadEventCount, 1)
    }

    /// Test that the legacy stores are kept when it cannot be told whether the new store holds a session
    ///
    /// - Given: A legacy store in which every value can be read, and a new credential store whose read
    ///   fails with a keychain error
    /// - When:
    ///    - The migration legacy store action is executed
    /// - Then:
    ///    - Nothing is saved and none of the legacy stores are removed
    ///    - A .loadCredentialStore event with type .amplifyCredentials is dispatched
    ///
    func testExecute_whenNewStoreIsUnreadable_shouldKeepLegacyStores() async {
        let result = await runMigration(
            legacyKeychainStore: MockKeychainStoreBehavior(data: "mock"),
            existingCredentials: { throw EngineCredentialStoreError.securityError(errSecInteractionNotAllowed) }
        )
        XCTAssertEqual(result.savedCredentialCount, 0)
        XCTAssertEqual(result.savedDeviceCount, 0)
        XCTAssertEqual(result.removeAllCount, 0)
        XCTAssertEqual(result.loadEventCount, 1)
    }

    /// Test that an empty new credential store is migrated into as before
    ///
    /// - Given: A legacy store in which every value can be read, and a new credential store that holds
    ///   no session (`.noCredentials`)
    /// - When:
    ///    - The migration legacy store action is executed
    /// - Then:
    ///    - The legacy credentials are saved and the legacy stores are each removed once
    ///
    func testExecute_whenNewStoreHasNoCredentials_shouldMigrate() async {
        let result = await runMigration(
            legacyKeychainStore: MockKeychainStoreBehavior(data: "mock"),
            existingCredentials: { AmplifyCredentials.noCredentials }
        )
        XCTAssertEqual(result.savedCredentialCount, 1)
        XCTAssertEqual(result.removeAllCount, 3)
        XCTAssertEqual(result.loadEventCount, 1)
    }

    /// Test that a legacy value which cannot be decoded is still treated as absent, as before
    ///
    /// - Given: A legacy store whose refresh token cannot be converted to a string
    /// - When:
    ///    - The migration legacy store action is executed
    /// - Then:
    ///    - The user pool, identity pool and mobile client legacy stores are each removed once
    ///
    func testExecute_whenLegacyValueCannotBeConverted_shouldClearLegacyStores() async {
        let result = await runMigration(
            legacyKeychainStore: MockKeychainStoreBehavior(
                data: "mock",
                readErrorForKey: { key in
                    key.hasSuffix(".refreshToken") ? EngineCredentialStoreError.conversionError("Unable to create String from Data") : nil
                }
            )
        )
        XCTAssertEqual(result.removeAllCount, 3)
        XCTAssertEqual(result.loadEventCount, 1)
    }

    /// Test that a keychain error is ignored when the legacy stores hold nothing
    ///
    /// - Given: Legacy stores that report no items, but whose reads fail with a keychain error
    /// - When:
    ///    - The migration legacy store action is executed
    /// - Then:
    ///    - The error does not hold the migration in the keep path: nothing is saved and the (empty)
    ///      legacy stores are each removed once, as before
    ///
    func testExecute_whenLegacyReadFailsButLegacyStoresAreEmpty_shouldClearLegacyStores() async {
        let result = await runMigration(
            legacyKeychainStore: MockKeychainStoreBehavior(
                data: "",
                readErrorForKey: { _ in EngineCredentialStoreError.securityError(errSecMissingEntitlement) }
            )
        )
        XCTAssertEqual(result.savedCredentialCount, 0)
        XCTAssertEqual(result.removeAllCount, 3)
        XCTAssertEqual(result.loadEventCount, 1)
    }

    /// Test that a locked keychain keeps the legacy stores even when they are reported as empty
    ///
    /// - Given: Legacy stores whose reads all fail with `errSecInteractionNotAllowed` (the device is
    ///   locked), and whose item check reports no items
    /// - When:
    ///    - The migration legacy store action is executed
    /// - Then:
    ///    - The error is not discarded: none of the legacy stores are removed, nothing is saved, and a
    ///      .loadCredentialStore event is dispatched, so the migration is retried on a later launch
    ///
    func testExecute_whenLegacyReadIsNotAllowedAndLegacyStoresReportEmpty_shouldKeepLegacyStores() async {
        let result = await runMigration(
            legacyKeychainStore: MockKeychainStoreBehavior(
                data: "",
                readErrorForKey: { _ in EngineCredentialStoreError.securityError(errSecInteractionNotAllowed) }
            )
        )
        XCTAssertEqual(result.removeAllCount, 0)
        XCTAssertEqual(result.savedCredentialCount, 0)
        XCTAssertEqual(result.savedDeviceCount, 0)
        XCTAssertEqual(result.loadEventCount, 1)
    }

    /// Test that legacy stores whose contents cannot be determined are kept
    ///
    /// - Given: Legacy stores whose reads fail with a keychain error, and whose item check also throws
    /// - When:
    ///    - The migration legacy store action is executed
    /// - Then:
    ///    - The stores count as possibly holding items: none of them are removed, nothing is saved, and
    ///      a .loadCredentialStore event is dispatched
    ///
    func testExecute_whenLegacyReadFailsAndItemCheckFails_shouldKeepLegacyStores() async {
        let result = await runMigration(
            legacyKeychainStore: MockKeychainStoreBehavior(
                data: "",
                readErrorForKey: { _ in EngineCredentialStoreError.securityError(errSecMissingEntitlement) },
                hasItemsError: EngineCredentialStoreError.securityError(errSecMissingEntitlement)
            )
        )
        XCTAssertEqual(result.removeAllCount, 0)
        XCTAssertEqual(result.savedCredentialCount, 0)
        XCTAssertEqual(result.savedDeviceCount, 0)
        XCTAssertEqual(result.loadEventCount, 1)
    }

    private final class MigrationResult: @unchecked Sendable {
        var removeAllCount = 0
        var savedCredentialCount = 0
        var savedDeviceCount = 0
        var loadEventCount = 0
    }

    private func runMigration(
        legacyKeychainStore: MockKeychainStoreBehavior,
        existingCredentials: MockAmplifyCredentialStoreBehavior.GetCredentialHandler? = nil
    ) async -> MigrationResult {
        let result = MigrationResult()
        let countingLegacyStore = MockKeychainStoreBehavior(
            data: legacyKeychainStore.data,
            removeAllHandler: { result.removeAllCount += 1 },
            readErrorForKey: legacyKeychainStore.readErrorForKey,
            hasItemsError: legacyKeychainStore.hasItemsError
        )
        let amplifyCredentialStore = MockAmplifyCredentialStoreBehavior(
            saveCredentialHandler: { _ in result.savedCredentialCount += 1 },
            getCredentialHandler: existingCredentials
        )
        amplifyCredentialStore.saveDeviceHandler = { _ in result.savedDeviceCount += 1 }

        let action = MigrateLegacyCredentialStore()
        await action.execute(
            withDispatcher: MockDispatcher { event in
                if let event = event as? CredentialStoreEvent,
                   case .loadCredentialStore(.amplifyCredentials) = event.eventType {
                    result.loadEventCount += 1
                }
            },
            environment: makeEnvironment(
                legacyKeychainStore: countingLegacyStore,
                amplifyCredentialStore: amplifyCredentialStore
            )
        )
        return result
    }
}
