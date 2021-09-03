//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import XCTest
import Combine

import AmplifyPlugins
import AWSDataStoreCategoryPlugin
import AWSPluginsCore

@testable import Amplify
@testable import AmplifyTestCommon

class AWSDataStoreMultiAuthBaseTest: XCTestCase {
    var requests: Set<AnyCancellable> = []

    var user1: TestUser?
    var user2: TestUser?

    static let amplifyConfigurationFile = "AWSDataStoreCategoryPluginMultiAuthIntegrationTests-amplifyconfiguration"
    static let credentialsFile = "AWSDataStoreCategoryPluginMultiAuthIntegrationTests-credentials"

    var authRecorderInterceptor: AuthRecorderInterceptor!

    override func setUp() {
        continueAfterFailure = false

        Amplify.Logging.logLevel = .verbose

        do {
            let credentials = try TestConfigHelper.retrieveCredentials(forResource: Self.credentialsFile)

            guard let user1 = credentials["user1"],
                  let user2 = credentials["user2"],
                  let passwordUser1 = credentials["passwordUser1"],
                  let passwordUser2 = credentials["passwordUser2"] else {
                XCTFail("Invalid \(Self.credentialsFile).json data")
                return
            }

            self.user1 = TestUser(username: user1, password: passwordUser1)
            self.user2 = TestUser(username: user2, password: passwordUser2)

            authRecorderInterceptor = AuthRecorderInterceptor()

        } catch {
            XCTFail("Error during setup: \(error)")
        }
    }

    override func tearDownWithError() throws {
        let stopped = expectation(description: "stopped")
        Amplify.DataStore.stop { _ in stopped.fulfill() }
        waitForExpectations(timeout: 1.0)

        requests.forEach { $0.cancel() }
        requests = []

        Amplify.reset()
    }

    // MARK: - Test Helpers
    func makeExpectations() -> MultiAuthTestExpectations {
        MultiAuthTestExpectations(
            subscriptionsEstablished: expectation(description: "Subscriptions established"),
            modelsSynced: expectation(description: "Models synced"),

            query: expectation(description: "Query success"),

            mutationSave: expectation(description: "Mutation save success"),
            mutationSaveProcessed: expectation(description: "Mutation save processed"),

            mutationDelete: expectation(description: "Mutation delete success"),
            mutationDeleteProcessed: expectation(description: "Mutation delete processed"),

            ready: expectation(description: "Ready")
        )
    }

    /// Setup DataStore with given models
    /// - Parameter models: DataStore models
    func setup(withModels models: AmplifyModelRegistration) {
        do {
            let datastoreConfig = DataStoreConfiguration.custom(authModeStrategy: .multiAuth)

            try Amplify.add(plugin: AWSDataStorePlugin(modelRegistration: models,
                                                       configuration: datastoreConfig))

            let apiPlugin = AWSAPIPlugin()

            try Amplify.add(plugin: apiPlugin)
            try Amplify.add(plugin: AWSCognitoAuthPlugin())

            let amplifyConfig = try TestConfigHelper.retrieveAmplifyConfiguration(forResource: Self.amplifyConfigurationFile)
            try Amplify.configure(amplifyConfig)

            // register auth recorder interceptor
            try apiPlugin.add(interceptor: authRecorderInterceptor, for: "datastoreintegtestmu")

            signOut()
            clearDataStore()
        } catch {
            XCTFail("Error during setup: \(error)")
        }
    }

    func clearDataStore() {
        let semaphore = DispatchSemaphore(value: 0)
        Amplify.DataStore.clear {
            if case let .failure(error) = $0 {
                XCTFail("DataStore clear failed \(error)")
            }
            semaphore.signal()
        }
        semaphore.wait()
    }
}

// MARK: - Auth helpers
extension AWSDataStoreMultiAuthBaseTest {
    /// Signin given user
    /// - Parameter user
    func signIn(user: TestUser?) {
        guard let user = user else {
            XCTFail("Invalid user")
            return
        }
        let signInInvoked = expectation(description: "sign in completed")
        _ = Amplify.Auth.signIn(username: user.username,
                                password: user.password, options: nil) { result in
            switch result {
            case .failure(let error):
                XCTFail("Signin failure \(error)")
                signInInvoked.fulfill() // won't count as pass
            case .success:
                signInInvoked.fulfill()
            }
        }
        wait(for: [signInInvoked], timeout: TestCommonConstants.networkTimeout)
    }

    /// Signout current signed-in user
    func signOut() {
        let signoutInvoked = expectation(description: "sign out completed")
        _ = Amplify.Auth.signOut { result in
            switch result {
            case .failure(let error):
                XCTFail("Signout failure \(error)")
                signoutInvoked.fulfill() // won't count as pass

            case .success:
                signoutInvoked.fulfill()
            }
        }
        wait(for: [signoutInvoked], timeout: TestCommonConstants.networkTimeout)
    }
}

// MARK: - DataStore behavior assert helpers
extension AWSDataStoreMultiAuthBaseTest {
    /// Asserts that query with given `Model` succeeds
    /// - Parameters:
    ///   - modelType: model type
    ///   - expectation: success XCTestExpectation
    ///   - onFailure: on failure callback
    func assertQuerySuccess<M: Model>(modelType: M.Type,
                                      _ expectations: MultiAuthTestExpectations,
                                      onFailure: @escaping (_ error: DataStoreError) -> Void) {
        Amplify.DataStore.query(modelType).sink {
            if case let .failure(error) = $0 {
                onFailure(error)
            }
        }
        receiveValue: { posts in
            XCTAssertNotNil(posts)
            expectations.query.fulfill()
        }.store(in: &requests)
        wait(for: [expectations.query],
             timeout: 60)
    }

    /// Asserts that DataStore is in a ready state and subscriptions are established
    /// - Parameter events: DataStore Hub events
    func assertDataStoreReady(_ expectations: MultiAuthTestExpectations,
                              expectedModelSynced: Int = 1) {
        var modelSyncedCount = 0
        let dataStoreEvents = HubPayload.EventName.DataStore.self
        Amplify
            .Hub
            .publisher(for: .dataStore)
            .sink { event in
                // subscription fulfilled
                if event.eventName == dataStoreEvents.subscriptionsEstablished {
                    expectations.subscriptionsEstablished.fulfill()
                }

                // syncQueryReady fulfilled
                if event.eventName == dataStoreEvents.modelSynced {
                    modelSyncedCount += 1
                    if modelSyncedCount == expectedModelSynced {
                        expectations.modelsSynced.fulfill()
                    }
                }

                if event.eventName == dataStoreEvents.ready {
                    expectations.ready.fulfill()
                }
            }
            .store(in: &requests)

        Amplify.DataStore.start { _ in }

        wait(for: [expectations.subscriptionsEstablished,
                   expectations.modelsSynced,
                   expectations.ready],
             timeout: 60)

    }

    /// Assert that a save and a delete mutation complete successfully.
    /// - Parameters:
    ///   - model: model instance saved and then deleted
    ///   - expectations: test expectatinos
    ///   - onFailure: failure callback
    func assertMutations<M: Model>(model: M,
                                   _ expectations: MultiAuthTestExpectations,
                                   onFailure: @escaping (_ error: DataStoreError) -> Void) {
        Amplify
            .Hub
            .publisher(for: .dataStore)
            .filter { $0.eventName == HubPayload.EventName.DataStore.syncReceived }
            .sink { payload in
                guard let mutationEvent = payload.data as? MutationEvent,
                      mutationEvent.modelId == model.id else {
                    return
                }

                if mutationEvent.mutationType == GraphQLMutationType.create.rawValue {
                    expectations.mutationSaveProcessed.fulfill()
                    return
                }

                if mutationEvent.mutationType == GraphQLMutationType.delete.rawValue {
                    expectations.mutationDeleteProcessed.fulfill()
                    return
                }
            }
            .store(in: &requests)

        Amplify.DataStore.save(model).sink {
            if case let .failure(error) = $0 {
                onFailure(error)
            }
        }
        receiveValue: { posts in
            XCTAssertNotNil(posts)
            expectations.mutationSave.fulfill()
        }.store(in: &requests)

        wait(for: [expectations.mutationSave, expectations.mutationSaveProcessed], timeout: 60)

        Amplify.DataStore.delete(M.self, withId: model.id).sink {
            if case let .failure(error) = $0 {
                onFailure(error)
            }
        }
        receiveValue: { posts in
            XCTAssertNotNil(posts)
            expectations.mutationDelete.fulfill()
        }.store(in: &requests)

        wait(for: [expectations.mutationDelete, expectations.mutationDeleteProcessed], timeout: 60)
    }

    /// Asserts that save mutation with given `Model` succeeds
    /// - Parameters:
    ///   - model: model type
    ///   - expectation: success XCTestExpectation
    ///   - onFailure: on failure callback
    func assertMutations<M: Model>(model: M,
                                   _ expectation: XCTestExpectation,
                                   onFailure: @escaping (_ error: DataStoreError) -> Void) {
        Amplify.DataStore.save(model).sink {
            if case let .failure(error) = $0 {
                onFailure(error)
            }
        }
        receiveValue: { posts in
            XCTAssertNotNil(posts)
            expectation.fulfill()
        }.store(in: &requests)
    }

    func assertUsedAuthTypes(_ authTypes: [AWSAuthorizationType],
                             file: StaticString = #file,
                             line: UInt = #line) {
        XCTAssertEqual(authRecorderInterceptor.consumedAuthTypes,
                       Set(authTypes),
                       file: file,
                       line: line)
    }
}

// MARK: - Expectations
extension AWSDataStoreMultiAuthBaseTest {
    struct MultiAuthTestExpectations {
        var subscriptionsEstablished: XCTestExpectation
        var modelsSynced: XCTestExpectation
        var query: XCTestExpectation
        var mutationSave: XCTestExpectation
        var mutationSaveProcessed: XCTestExpectation
        var mutationDelete: XCTestExpectation
        var mutationDeleteProcessed: XCTestExpectation
        var ready: XCTestExpectation
        var expectations: [XCTestExpectation] {
            return [subscriptionsEstablished,
                    modelsSynced,
                    query,
                    mutationSave,
                    mutationSaveProcessed
            ]
        }
    }
}
