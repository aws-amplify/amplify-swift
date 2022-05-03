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

class AWSDataStoreAuthBaseTest: XCTestCase {
    var requests: Set<AnyCancellable> = []

    var amplifyConfig: AmplifyConfiguration!
    var user1: TestUser?
    var user2: TestUser?
    var authRecorderInterceptor: AuthRecorderInterceptor!

    override func setUp() {
        continueAfterFailure = false
    }

    override func tearDownWithError() throws {
        clearDataStore()
        requests = []
        signOut()
        Amplify.reset()
    }

    // MARK: - Test Helpers
    func makeExpectations() -> AuthTestExpectations {
        AuthTestExpectations(
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

    func setupCredentials(forAuthStrategy testType: DataStoreAuthTestType) {
        let configFile: String
        let credentialsFile: String
        let basePath = "testconfiguration"

        switch testType {
        case .defaultAuthCognito:
            let baseFileName = "AWSDataStoreCategoryPluginAuthIntegrationTests"
            configFile = "\(basePath)/\(baseFileName)-amplifyconfiguration"
            credentialsFile = "\(basePath)/\(baseFileName)-credentials"

        case .defaultAuthIAM:
            let baseFileName = "AWSDataStoreCategoryPluginAuthIAMIntegrationTests"
            configFile = "\(basePath)/\(baseFileName)-amplifyconfiguration"
            credentialsFile = "\(basePath)/\(baseFileName)-credentials"

        case .multiAuth:
            let baseFileName = "AWSDataStoreCategoryPluginMultiAuthIntegrationTests"
            configFile = "\(basePath)/\(baseFileName)-amplifyconfiguration"
            credentialsFile = "\(basePath)/\(baseFileName)-credentials"
        }

        do {
            let credentials = try TestConfigHelper.retrieveCredentials(forResource: credentialsFile)

            guard let user1 = credentials["user1"],
                  let user2 = credentials["user2"],
                  let passwordUser1 = credentials["passwordUser1"],
                  let passwordUser2 = credentials["passwordUser2"] else {
                XCTFail("Invalid \(credentialsFile).json data")
                return
            }

            self.user1 = TestUser(username: user1, password: passwordUser1)
            self.user2 = TestUser(username: user2, password: passwordUser2)

            authRecorderInterceptor = AuthRecorderInterceptor()

            amplifyConfig = try TestConfigHelper.retrieveAmplifyConfiguration(forResource: configFile)

        } catch {
            XCTFail("Error during setup: \(error)")
        }

    }

    func apiEndpointName() throws -> String {
        guard let apiPlugin = amplifyConfig.api?.plugins["awsAPIPlugin"],
              case .object(let value) = apiPlugin else {
            throw APIError.invalidConfiguration("API endpoint not found.", "Check the provided configuration")
        }
        return value.keys.first!
    }

    /// Setup DataStore with given models
    /// - Parameter models: DataStore models
    func setup(withModels models: AmplifyModelRegistration,
               testType: DataStoreAuthTestType,
               apiPluginFactory: () -> AWSAPIPlugin = { AWSAPIPlugin() }) {
        do {
            setupCredentials(forAuthStrategy: testType)

            let datastoreConfig = DataStoreConfiguration.custom(authModeStrategy: testType.authStrategy)

            try Amplify.add(plugin: AWSDataStorePlugin(modelRegistration: models,
                                                       configuration: datastoreConfig))

            let apiPlugin = apiPluginFactory()

            try Amplify.add(plugin: apiPlugin)
            try Amplify.add(plugin: AWSCognitoAuthPlugin())

            Amplify.Logging.logLevel = .verbose

            try Amplify.configure(amplifyConfig)

            // register auth recorder interceptor
            let apiName = try apiEndpointName()
            try apiPlugin.add(interceptor: authRecorderInterceptor, for: apiName)

            signOut()
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
extension AWSDataStoreAuthBaseTest {
    /// Signin given user
    /// - Parameter user
    func signIn(user: TestUser?,
                file: StaticString = #file,
                line: UInt = #line) {
        guard let user = user else {
            XCTFail("Invalid user", file: file, line: line)
            return
        }
        let signInInvoked = expectation(description: "sign in completed")
        _ = Amplify.Auth.signIn(username: user.username,
                                password: user.password, options: nil) { result in
            switch result {
            case .failure(let error):
                XCTFail("Signin failure \(error)", file: file, line: line)
                signInInvoked.fulfill() // won't count as pass
            case .success:
                signInInvoked.fulfill()
            }
        }
        wait(for: [signInInvoked], timeout: TestCommonConstants.networkTimeout)
        XCTAssert(isSignedIn(), file: file, line: line)
    }

    /// Signout current signed-in user
    func signOut(file: StaticString = #file,
                 line: UInt = #line) {
        let signoutInvoked = expectation(description: "sign out completed")
        _ = Amplify.Auth.signOut { result in
            switch result {
            case .failure(let error):
                XCTFail("Signout failure \(error)", file: file, line: line)
                signoutInvoked.fulfill() // won't count as pass

            case .success:
                signoutInvoked.fulfill()
            }
        }
        wait(for: [signoutInvoked], timeout: TestCommonConstants.networkTimeout)
        XCTAssert(!isSignedIn(), file: file, line: line)
    }

    func isSignedIn() -> Bool {
        let checkIsSignedInCompleted = expectation(description: "retrieve auth session completed")
        var resultOptional: Bool?
        _ = Amplify.Auth.fetchAuthSession { event in
            switch event {
            case .success(let authSession):
                resultOptional = authSession.isSignedIn
                checkIsSignedInCompleted.fulfill()
            case .failure(let error):
                fatalError("Failed to get auth session \(error)")
            }
        }
        wait(for: [checkIsSignedInCompleted], timeout: TestCommonConstants.networkTimeout)
        guard let result = resultOptional else {
            XCTFail("Could not get isSignedIn for user")
            return false
        }

        return result
    }

    func getUserSub() -> String {
        let retrieveUserSubCompleted = expectation(description: "retrieve userSub completed")
        var resultOptional: String?
        _ = Amplify.Auth.fetchAuthSession(listener: { event in
            switch event {
            case .success(let authSession):
                guard let cognitoAuthSession = authSession as? AuthCognitoIdentityProvider else {
                    XCTFail("Could not get auth session as AuthCognitoIdentityProvider")
                    return
                }
                switch cognitoAuthSession.getUserSub() {
                case .success(let userSub):
                    resultOptional = userSub
                    retrieveUserSubCompleted.fulfill()
                case .failure(let error):
                    XCTFail("Failed to get auth session \(error)")
                }
            case .failure(let error):
                XCTFail("Failed to get auth session \(error)")
            }
        })
        wait(for: [retrieveUserSubCompleted], timeout: TestCommonConstants.networkTimeout)
        guard let result = resultOptional else {
            XCTFail("Could not get userSub for user")
            return ""
        }

        return result
    }

    func getIdentityId() -> String {
        let retrieveIdentityCompleted = expectation(description: "retrieve identity completed")
        var resultOptional: String?
        _ = Amplify.Auth.fetchAuthSession(listener: { event in
            switch event {
            case .success(let authSession):
                guard let cognitoAuthSession = authSession as? AuthCognitoIdentityProvider else {
                    XCTFail("Could not get auth session as AuthCognitoIdentityProvider")
                    return
                }
                switch cognitoAuthSession.getIdentityId() {
                case .success(let identityId):
                    resultOptional = identityId
                    retrieveIdentityCompleted.fulfill()
                case .failure(let error):
                    XCTFail("Failed to get auth session \(error)")
                }
            case .failure(let error):
                XCTFail("Failed to get auth session \(error)")
            }
        })
        wait(for: [retrieveIdentityCompleted], timeout: TestCommonConstants.networkTimeout)
        guard let result = resultOptional else {
            XCTFail("Could not get identityId for user")
            return ""
        }

        return result
    }

    func queryModel<M: Model>(_ model: M.Type,
                              byId id: String,
                              file: StaticString = #file,
                              line: UInt = #line) -> M? {
        var queriedModel: M?
        let queriedInvoked = expectation(description: "Model queried")

        Amplify.DataStore.query(M.self, byId: id) { result in
            switch result {
            case .success(let model):
                queriedModel = model
                queriedInvoked.fulfill()
            case .failure(let error):
                XCTFail("Failed to query model \(error)", file: file, line: line)
            }
        }

        wait(for: [queriedInvoked], timeout: TestCommonConstants.networkTimeout)
        return queriedModel
    }
}

// MARK: - DataStore behavior assert helpers
extension AWSDataStoreAuthBaseTest {
    /// Asserts that query with given `Model` succeeds
    /// - Parameters:
    ///   - modelType: model type
    ///   - expectation: success XCTestExpectation
    ///   - onFailure: on failure callback
    func assertQuerySuccess<M: Model>(modelType: M.Type,
                                      _ expectations: AuthTestExpectations,
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
    func assertDataStoreReady(_ expectations: AuthTestExpectations,
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

                // modelsSynced fulfilled
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
    ///   - expectations: test expectations
    ///   - onFailure: failure callback
    func assertMutations<M: Model>(model: M,
                                   _ expectations: AuthTestExpectations,
                                   onFailure: @escaping (_ error: DataStoreError) -> Void) {
        Amplify
            .Hub
            .publisher(for: .dataStore)
            .filter { $0.eventName == HubPayload.EventName.DataStore.syncReceived }
            .sink { payload in
                guard let mutationEvent = payload.data as? MutationEvent,
                      mutationEvent.modelId == model.identifier else {
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
extension AWSDataStoreAuthBaseTest {
    struct AuthTestExpectations {
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

    enum DataStoreAuthTestType {
        case defaultAuthCognito
        case defaultAuthIAM
        case multiAuth

        var authStrategy: AuthModeStrategyType {
            switch self {
            case .defaultAuthCognito:
                return .default
            case .defaultAuthIAM:
                return .default
            case .multiAuth:
                return .multiAuth
            }
        }
    }
}
