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
    var requests: Set<AnyCancellable> = []

    var amplifyConfig: AmplifyConfiguration!
    var user1: TestUser?
    var user2: TestUser?
    var authRecorderInterceptor: AuthRecorderInterceptor!

    override func setUp() {
        continueAfterFailure = false
    }

    override func tearDown() async throws {
        try await clearDataStore()
        requests = []
        await signOut()
        await Amplify.reset()
    }

    // MARK: - Test Helpers
    func makeExpectations() -> AuthTestExpectations {
        AuthTestExpectations(
            subscriptionsEstablished: AsyncExpectation(description: "Subscriptions established"),
            modelsSynced: AsyncExpectation(description: "Models synced"),

            query: AsyncExpectation(description: "Query success"),

            mutationSave: AsyncExpectation(description: "Mutation save success"),
            mutationSaveProcessed: AsyncExpectation(description: "Mutation save processed"),

            mutationDelete: AsyncExpectation(description: "Mutation delete success"),
            mutationDeleteProcessed: AsyncExpectation(description: "Mutation delete processed"),

            ready: AsyncExpectation(description: "Ready")
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
    ) async {
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

            await signOut()
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
                line: UInt = #line) async {
        guard let user = user else {
            XCTFail("Invalid user", file: file, line: line)
            return
        }
        let signInInvoked = AsyncExpectation(description: "sign in completed")
        do {
            _ = try await Amplify.Auth.signIn(username: user.username,
                                                       password: user.password,
                                                       options: nil)
            Task {
                await signInInvoked.fulfill()
            }
        } catch(let error) {
            XCTFail("Signin failure \(error)", file: file, line: line)
            Task {
                await signInInvoked.fulfill() // won't count as pass
            }
        }
        await waitForExpectations([signInInvoked], timeout: TestCommonConstants.networkTimeout)
        
        let signedIn = await isSignedIn()
        XCTAssert(signedIn, file: file, line: line)
    }

    /// Signout current signed-in user
    func signOut(file: StaticString = #file,
                 line: UInt = #line) async {
        let signoutInvoked = AsyncExpectation(description: "sign out completed")
        Task {
            _ = await Amplify.Auth.signOut()
            await signoutInvoked.fulfill()
        }
        
        await waitForExpectations([signoutInvoked], timeout: TestCommonConstants.networkTimeout)
        
        let signedIn = await isSignedIn()
        XCTAssert(!signedIn, file: file, line: line)
    }

    func isSignedIn() async -> Bool {
        let checkIsSignedInCompleted = AsyncExpectation(description: "retrieve auth session completed")
        var resultOptional: Bool?
        do {
            let authSession = try await Amplify.Auth.fetchAuthSession()
            resultOptional = authSession.isSignedIn
            Task {
                await checkIsSignedInCompleted.fulfill()
            }
        } catch(let error) {
            fatalError("Failed to get auth session \(error)")
        }
        
        await waitForExpectations([checkIsSignedInCompleted], timeout: TestCommonConstants.networkTimeout)
        guard let result = resultOptional else {
            XCTFail("Could not get isSignedIn for user")
            return false
        }

        return result
    }

    func getUserSub() async -> String {
        let retrieveUserSubCompleted = AsyncExpectation(description: "retrieve userSub completed")
        var resultOptional: String?
        do {
            let authSession = try await Amplify.Auth.fetchAuthSession()
            guard let cognitoAuthSession = authSession as? AuthCognitoIdentityProvider else {
                XCTFail("Could not get auth session as AuthCognitoIdentityProvider")
                return ""
            }
            switch cognitoAuthSession.getUserSub() {
            case .success(let userSub):
                resultOptional = userSub
                Task {
                    await retrieveUserSubCompleted.fulfill()
                }
            case .failure(let error):
                XCTFail("Failed to get auth session \(error)")
            }
        } catch(let error) {
            XCTFail("Failed to get auth session \(error)")
        }

        await waitForExpectations([retrieveUserSubCompleted], timeout: TestCommonConstants.networkTimeout)
        guard let result = resultOptional else {
            XCTFail("Could not get userSub for user")
            return ""
        }

        return result
    }

    func getIdentityId() async -> String {
        let retrieveIdentityCompleted = AsyncExpectation(description: "retrieve identity completed")
        var resultOptional: String?
        do {
            let authSession = try await Amplify.Auth.fetchAuthSession()
            guard let cognitoAuthSession = authSession as? AuthCognitoIdentityProvider else {
                XCTFail("Could not get auth session as AuthCognitoIdentityProvider")
                return ""
            }
            switch cognitoAuthSession.getIdentityId() {
            case .success(let identityId):
                resultOptional = identityId
                Task {
                    await retrieveIdentityCompleted.fulfill()
                }
            case .failure(let error):
                XCTFail("Failed to get auth session \(error)")
            }
        } catch(let error) {
            XCTFail("Failed to get auth session \(error)")
        }
        await waitForExpectations([retrieveIdentityCompleted], timeout: TestCommonConstants.networkTimeout)
        guard let result = resultOptional else {
            XCTFail("Could not get identityId for user")
            return ""
        }

        return result
    }

    func queryModel<M: Model>(_ model: M.Type,
                              byId id: String,
                              file: StaticString = #file,
                              line: UInt = #line) async -> M? {
        var queriedModel: M?
        let queriedInvoked = AsyncExpectation(description: "Model queried")

        do {
            let model = try await Amplify.DataStore.query(M.self, byId: id)
            queriedModel = model
            Task {
                await queriedInvoked.fulfill()
            }
        } catch(let error) {
            XCTFail("Failed to query model \(error)", file: file, line: line)
        }
        
        await waitForExpectations([queriedInvoked], timeout: TestCommonConstants.networkTimeout)
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
                                      onFailure: @escaping (_ error: DataStoreError) -> Void) async {
        Amplify.Publisher.create {
            try await Amplify.DataStore.query(modelType)
        }.sink {
            if case let .failure(error) = $0 {
                onFailure(error as! DataStoreError)
            }
        }
        receiveValue: { posts in
            XCTAssertNotNil(posts)
            Task {
                await expectations.query.fulfill()
            }
        }.store(in: &requests)
        await waitForExpectations([expectations.query],
             timeout: 60)
    }

    /// Asserts that DataStore is in a ready state and subscriptions are established
    /// - Parameter events: DataStore Hub events
    func assertDataStoreReady(_ expectations: AuthTestExpectations,
                              expectedModelSynced: Int = 1) async {
        var modelSyncedCount = 0
        let dataStoreEvents = HubPayload.EventName.DataStore.self
        Amplify
            .Hub
            .publisher(for: .dataStore)
            .sink { event in
                // subscription fulfilled
                if event.eventName == dataStoreEvents.subscriptionsEstablished {
                    Task {
                        await expectations.subscriptionsEstablished.fulfill()
                    }
                }

                // modelsSynced fulfilled
                if event.eventName == dataStoreEvents.modelSynced {
                    modelSyncedCount += 1
                    if modelSyncedCount == expectedModelSynced {
                        Task {
                            await expectations.modelsSynced.fulfill()
                        }
                    }
                }

                if event.eventName == dataStoreEvents.ready {
                    Task {
                        await expectations.ready.fulfill()
                    }
                }
            }
            .store(in: &requests)

        do {
            try await Amplify.DataStore.start()
        } catch(let error) {
            XCTFail("Failure due to error: \(error)")
        }
        await waitForExpectations([expectations.subscriptionsEstablished,
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
                                   onFailure: @escaping (_ error: DataStoreError) -> Void) async {
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
                    Task {
                        await expectations.mutationSaveProcessed.fulfill()
                    }
                    return
                }

                if mutationEvent.mutationType == GraphQLMutationType.delete.rawValue {
                    Task {
                        await expectations.mutationDeleteProcessed.fulfill()
                    }
                    return
                }
            }
            .store(in: &requests)

        Amplify.Publisher.create {
            try await Amplify.DataStore.save(model)
        }.sink {
            if case let .failure(error) = $0 {
                onFailure(error as! DataStoreError)
            }
        }
        receiveValue: { posts in
            XCTAssertNotNil(posts)
            Task {
                await expectations.mutationSave.fulfill()
            }
        }.store(in: &requests)

        await waitForExpectations([expectations.mutationSave, expectations.mutationSaveProcessed], timeout: 60)

        Amplify.Publisher.create {
            try await Amplify.DataStore.delete(model)
        }.sink {
            if case let .failure(error) = $0 {
                onFailure(error as! DataStoreError)
            }
        }
        receiveValue: { posts in
            XCTAssertNotNil(posts)
            Task {
                await expectations.mutationDelete.fulfill()
            }
        }.store(in: &requests)

        await waitForExpectations([expectations.mutationDelete, expectations.mutationDeleteProcessed], timeout: 60)
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
