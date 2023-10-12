//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import XCTest
import Combine
import AWSDataStorePlugin
import AWSPluginsCore
import AWSAPIPlugin
import AWSCognitoAuthPlugin
#if !os(watchOS)
@testable import DataStoreHostApp
#endif

@testable import Amplify

struct TestUser {
    let username: String
    let password: String
}

class AuthRecorderInterceptor: URLRequestInterceptor {
    let awsAuthService: AWSAuthService = AWSAuthService()
    var consumedAuthTypes: Set<AWSAuthorizationType> = []
    private let accessQueue = DispatchQueue(label: "com.amazon.AuthRecorderInterceptor.consumedAuthTypes")

    private func recordAuthType(_ authType: AWSAuthorizationType) {
        accessQueue.async {
            self.consumedAuthTypes.insert(authType)
        }
    }

    func intercept(_ request: URLRequest) throws -> URLRequest {
        guard let headers = request.allHTTPHeaderFields else {
            fatalError("No headers found in request \(request)")
        }

        let authHeaderValue = headers["Authorization"]
        let apiKeyHeaderValue = headers["x-api-key"]

        if apiKeyHeaderValue != nil {
            recordAuthType(.apiKey)
        }

        if let authHeaderValue = authHeaderValue,
           case let .success(claims) = awsAuthService.getTokenClaims(tokenString: authHeaderValue),
           let cognitoIss = claims["iss"] as? String, cognitoIss.contains("cognito") {
            recordAuthType(.amazonCognitoUserPools)
        }

        if let authHeaderValue = authHeaderValue,
           authHeaderValue.starts(with: "AWS4-HMAC-SHA256") {
            recordAuthType(.awsIAM)
        }

        return request
    }

    func reset() {
        consumedAuthTypes = []
    }
}

class AWSDataStoreAuthBaseTest: XCTestCase {
    var amplifyConfig: AmplifyConfiguration!
    var user1: TestUser?
    var user2: TestUser?
    var authRecorderInterceptor: AuthRecorderInterceptor!

    override func setUp() {
        continueAfterFailure = false
    }

    override func tearDown() async throws {
        try await clearDataStore()
        try await signOut()
        await Amplify.reset()
        try await Task.sleep(seconds: 1)
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
    func setup(
        withModels models: AmplifyModelRegistration,
        testType: DataStoreAuthTestType,
        apiPluginFactory: () -> AWSAPIPlugin = { AWSAPIPlugin(sessionFactory: AmplifyURLSessionFactory()) }
    ) async throws {
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

            try await signOut()
        } catch {
            XCTFail("Error during setup: \(error)")
        }
    }

    func clearDataStore() async throws {
        try await Amplify.DataStore.clear()
    }
}

// MARK: - Auth helpers
extension AWSDataStoreAuthBaseTest {
    /// Signin given user
    /// - Parameter user
    func signIn(user: TestUser?,
                file: StaticString = #file,
                line: UInt = #line) async throws {
        guard let user = user else {
            XCTFail("Invalid user", file: file, line: line)
            return
        }
        do {
            let response = try await Amplify.Auth.signIn(username: user.username,
                                                     password: user.password, options: nil)
            print("received response for signIn \(response)")
            let isSignedIn = try await isSignedIn()
            XCTAssert(isSignedIn)
        } catch {
            XCTFail("SignIn failure \(error)", file: file, line: line)
            throw error
        }
    }

    /// Signout current signed-in user
    func signOut(file: StaticString = #file,
                 line: UInt = #line) async throws {
        do {
            _ = await Amplify.Auth.signOut()
            print("signOut successfull")
            let isSignedIn = try await isSignedIn()
            XCTAssertFalse(isSignedIn)
        } catch {
            XCTFail("SignOut failure \(error)", file: file, line: line)
            throw error
        }
    }

    func isSignedIn() async throws -> Bool {
        do {
            let authSession = try await Amplify.Auth.fetchAuthSession()
            return authSession.isSignedIn
        } catch {
            XCTFail("fetchAuthSession failure \(error)")
            throw error
        }
    }
    
    func getUserSub() async throws -> String {
        do {
            let authSession = try await Amplify.Auth.fetchAuthSession()
            let cognitoAuthSession = authSession as? AuthCognitoIdentityProvider
            guard let userSub = try cognitoAuthSession?.getUserSub().get() else {
                XCTFail("Missing userSub() from session")
                throw "Failed to get userSub"
            }
            return userSub
        } catch {
            XCTFail("Failed to get auth session \(error)")
            throw error
        }
    }
    
    func getIdentityId() async throws -> String! {
        do {
            let authSession = try await Amplify.Auth.fetchAuthSession()
            let cognitoAuthSession = authSession as? AuthCognitoIdentityProvider
            guard let identityId = try cognitoAuthSession?.getIdentityId().get() else {
                XCTFail("Failed to get identityId")
                throw "Failed to get identityId"
            }
            return identityId
        } catch {
            XCTFail("Failed to get auth session \(error)")
            throw error
        }
    }

    func queryModel<M: Model>(_ model: M.Type,
                              byId id: String,
                              file: StaticString = #file,
                              line: UInt = #line) async throws -> M? {
        return try await Amplify.DataStore.query(M.self, byId: id)
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
                                      onFailure: @escaping (_ error: DataStoreError) -> Void) async throws {
        Task {
            do {
                let posts = try await Amplify.DataStore.query(modelType)
                XCTAssertNotNil(posts)
                await expectations.query.fulfill()
            } catch {
                onFailure(error as! DataStoreError)
            }
        }
        await fulfillment(of: [expectations.query], timeout: 60)
    }
    
    /// Asserts that DataStore is in a ready state and subscriptions are established
    /// - Parameter events: DataStore Hub events
    func assertDataStoreReady(
        _ expectations: AuthTestExpectations,
        expectedModelSynced: Int = 1
    ) async throws {
        var requests: Set<AnyCancellable> = []
        var modelSyncedCount = 0
        let dataStoreEvents = HubPayload.EventName.DataStore.self
        Amplify
            .Hub
            .publisher(for: .dataStore)
            .sink { event in
                // subscription fulfilled
                if event.eventName == dataStoreEvents.subscriptionsEstablished {
                    Task { await expectations.subscriptionsEstablished.fulfill() }
                }
                // modelsSynced fulfilled
                if event.eventName == dataStoreEvents.modelSynced {
                    modelSyncedCount += 1
                    if modelSyncedCount == expectedModelSynced {
                        Task { await expectations.modelsSynced.fulfill() }
                    }
                }
                
                if event.eventName == dataStoreEvents.ready {
                    Task { await expectations.ready.fulfill() }
                }
            }
            .store(in: &requests)
        
        try await Amplify.DataStore.start()
        
        await fulfillment(of: [expectations.subscriptionsEstablished,
                                   expectations.modelsSynced,
                                   expectations.ready],
                                  timeout: 60)
    }
    
    /// Assert that a save and a delete mutation complete successfully.
    /// - Parameters:
    ///   - model: model instance saved and then deleted
    ///   - expectations: test expectations
    ///   - onFailure: failure callback
    func assertMutations<M: Model>(
        model: M,
        _ expectations: AuthTestExpectations,
        onFailure: @escaping (_ error: DataStoreError) -> Void
    ) async throws {
        var requests: Set<AnyCancellable> = []
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
                    Task { await expectations.mutationSaveProcessed.fulfill() }
                    return
                }

                if mutationEvent.mutationType == GraphQLMutationType.delete.rawValue {
                    Task { await expectations.mutationDeleteProcessed.fulfill() }
                    return
                }
            }
            .store(in: &requests)
        Task {
            do {
                let posts = try await Amplify.DataStore.save(model)
                XCTAssertNotNil(posts)
                Task { await expectations.mutationSave.fulfill() }
            } catch let error as DataStoreError {
                onFailure(error)
            }
        }
        await fulfillment(of: [expectations.mutationSave,
                                   expectations.mutationSaveProcessed], timeout: 60)
        Task {
            do {
                let deletedposts: () = try await Amplify.DataStore.delete(model)
                XCTAssertNotNil(deletedposts)
                Task { await expectations.mutationDelete.fulfill() }
            } catch let error as DataStoreError {
                onFailure(error)
            }
        }
        await fulfillment(of: [expectations.mutationDelete,
                                   expectations.mutationDeleteProcessed], timeout: 60)
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
        var subscriptionsEstablished: AsyncExpectation
        var modelsSynced: AsyncExpectation
        var query: AsyncExpectation
        var mutationSave: AsyncExpectation
        var mutationSaveProcessed: AsyncExpectation
        var mutationDelete: AsyncExpectation
        var mutationDeleteProcessed: AsyncExpectation
        var ready: AsyncExpectation
        var expectations: [AsyncExpectation] {
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
