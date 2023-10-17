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
@testable import AWSAPIPlugin
import AWSCognitoAuthPlugin

#if !os(watchOS)
@testable import DataStoreHostApp
#endif
@testable import Amplify

struct TestUser {
    let username: String
    let password: String
}


class DataStoreAuthBaseTestURLSessionFactory: URLSessionBehaviorFactory {
    static let testIdHeaderKey = "x-amplify-test"

    static let subject = PassthroughSubject<(String, Set<AWSAuthorizationType>), Never>()

    class Sniffer: URLProtocol {

        override class func canInit(with request: URLRequest) -> Bool {
            guard let headers = request.allHTTPHeaderFields else {
                fatalError("No headers found in request \(request)")
            }

            guard let testId = headers[DataStoreAuthBaseTestURLSessionFactory.testIdHeaderKey] else {
                return false
            }

            var result: Set<AWSAuthorizationType> = []
            let authHeaderValue = headers["Authorization"]
            let apiKeyHeaderValue = headers["x-api-key"]

            if apiKeyHeaderValue != nil {
                result.insert(.apiKey)
            }

            if let authHeaderValue = authHeaderValue,
               case let .success(claims) = AWSAuthService().getTokenClaims(tokenString: authHeaderValue),
               let cognitoIss = claims["iss"] as? String, cognitoIss.contains("cognito") {
                result.insert(.amazonCognitoUserPools)
            }

            if let authHeaderValue = authHeaderValue,
               authHeaderValue.starts(with: "AWS4-HMAC-SHA256") {
                result.insert(.awsIAM)
            }

            DataStoreAuthBaseTestURLSessionFactory.subject.send((testId, result))
            return false
        }

    }

    class Interceptor: URLRequestInterceptor {
        let testId: String?

        init(testId: String?) {
            self.testId = testId
        }

        func intercept(_ request: URLRequest) async throws -> URLRequest {
            if let testId {
                var mutableRequest = request
                mutableRequest.setValue(testId, forHTTPHeaderField: DataStoreAuthBaseTestURLSessionFactory.testIdHeaderKey)
                return mutableRequest
            }
            return request
        }
    }

    func makeSession(withDelegate delegate: URLSessionBehaviorDelegate?) -> URLSessionBehavior {
        let urlSessionDelegate = delegate?.asURLSessionDelegate
        let configuration = URLSessionConfiguration.default
        configuration.tlsMinimumSupportedProtocolVersion = .TLSv12
        configuration.tlsMaximumSupportedProtocolVersion = .TLSv13
        configuration.protocolClasses?.insert(Sniffer.self, at: 0)

        let session = URLSession(configuration: configuration,
                                 delegate: urlSessionDelegate,
                                 delegateQueue: nil)
        return AmplifyURLSession(session: session)
    }


}


class AWSDataStoreAuthBaseTest: XCTestCase {
    var requests: Set<AnyCancellable> = []

    var amplifyConfig: AmplifyConfiguration!
    var user1: TestUser?
    var user2: TestUser?

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
        testId: String? = nil,
        apiPluginFactory: () -> AWSAPIPlugin = { AWSAPIPlugin(sessionFactory: DataStoreAuthBaseTestURLSessionFactory()) }
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
            try apiPlugin.add(
                interceptor: DataStoreAuthBaseTestURLSessionFactory.Interceptor(testId: testId),
                for: apiName
            )

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
        let signInInvoked = expectation(description: "sign in completed")
        do {
            _ = try await Amplify.Auth.signIn(username: user.username,
                                                       password: user.password,
                                                       options: nil)
            signInInvoked.fulfill()
        } catch(let error) {
            XCTFail("Signin failure \(error)", file: file, line: line)
            signInInvoked.fulfill() // won't count as pass
        }
        await fulfillment(of: [signInInvoked], timeout: TestCommonConstants.networkTimeout)
        
        let signedIn = await isSignedIn()
        XCTAssert(signedIn, file: file, line: line)
    }

    /// Signout current signed-in user
    func signOut(file: StaticString = #file,
                 line: UInt = #line) async {
        let signoutInvoked = expectation(description: "sign out completed")
        Task {
            _ = await Amplify.Auth.signOut()
            signoutInvoked.fulfill()
        }
        
        await fulfillment(of: [signoutInvoked], timeout: TestCommonConstants.networkTimeout)
        
        let signedIn = await isSignedIn()
        XCTAssert(!signedIn, file: file, line: line)
    }


    func isSignedIn() async -> Bool {
        let checkIsSignedInCompleted = expectation(description: "retrieve auth session completed")
        var resultOptional: Bool?
        do {
            let authSession = try await Amplify.Auth.fetchAuthSession()
            resultOptional = authSession.isSignedIn
            checkIsSignedInCompleted.fulfill()
        } catch(let error) {
            fatalError("Failed to get auth session \(error)")
        }
        
        await fulfillment(of: [checkIsSignedInCompleted], timeout: TestCommonConstants.networkTimeout)
        guard let result = resultOptional else {
            XCTFail("Could not get isSignedIn for user")
            return false
        }

        return result
    }

    func getUserSub() async -> String {
        let retrieveUserSubCompleted = expectation(description: "retrieve userSub completed")
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
                retrieveUserSubCompleted.fulfill()
            case .failure(let error):
                XCTFail("Failed to get auth session \(error)")
            }
        } catch(let error) {
            XCTFail("Failed to get auth session \(error)")
        }

        await fulfillment(of: [retrieveUserSubCompleted], timeout: TestCommonConstants.networkTimeout)
        guard let result = resultOptional else {
            XCTFail("Could not get userSub for user")
            return ""
        }

        return result
    }

    func getIdentityId() async -> String {
        let retrieveIdentityCompleted = expectation(description: "retrieve identity completed")
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
                retrieveIdentityCompleted.fulfill()
            case .failure(let error):
                XCTFail("Failed to get auth session \(error)")
            }
        } catch(let error) {
            XCTFail("Failed to get auth session \(error)")
        }
        await fulfillment(of: [retrieveIdentityCompleted], timeout: TestCommonConstants.networkTimeout)
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
        let queriedInvoked = expectation(description: "Model queried")

        do {
            let model = try await Amplify.DataStore.query(M.self, byId: id)
            queriedModel = model
            queriedInvoked.fulfill()
        } catch(let error) {
            XCTFail("Failed to query model \(error)", file: file, line: line)
        }
        
        await fulfillment(of: [queriedInvoked], timeout: TestCommonConstants.networkTimeout)
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
            expectations.query.fulfill()
        }.store(in: &requests)
        await fulfillment(of: [expectations.query],
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

        do {
            try await Amplify.DataStore.start()
        } catch(let error) {
            XCTFail("Failure due to error: \(error)")
        }
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
                    expectations.mutationSaveProcessed.fulfill()
                    return
                }

                if mutationEvent.mutationType == GraphQLMutationType.delete.rawValue {
                    expectations.mutationDeleteProcessed.fulfill()
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
            expectations.mutationSave.fulfill()
        }.store(in: &requests)

        await fulfillment(of: [expectations.mutationSave, expectations.mutationSaveProcessed], timeout: 60)

        Amplify.Publisher.create {
            try await Amplify.DataStore.delete(model)
        }.sink {
            if case let .failure(error) = $0 {
                onFailure(error as! DataStoreError)
            }
        }
        receiveValue: { posts in
            XCTAssertNotNil(posts)
            expectations.mutationDelete.fulfill()
        }.store(in: &requests)

        await fulfillment(of: [expectations.mutationDelete, expectations.mutationDeleteProcessed], timeout: 60)
    }
    
    func assertUsedAuthTypes(
        testId: String,
        authTypes: [AWSAuthorizationType],
        file: StaticString = #file,
        line: UInt = #line
    ) -> XCTestExpectation {
        let expectation = expectation(description: "Should have expected auth types")
        expectation.assertForOverFulfill = false
        DataStoreAuthBaseTestURLSessionFactory.subject
        .filter { $0.0 == testId }
        .map { $0.1 }
        .collect(.byTime(DispatchQueue.global(), .milliseconds(3500)))
        .sink {
            let result = $0.reduce(Set<AWSAuthorizationType>()) { partialResult, data in
                partialResult.union(data)
            }
            XCTAssertEqual(result, Set(authTypes), file: file, line: line)
            expectation.fulfill()
        }
        .store(in: &requests)
        return expectation
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
