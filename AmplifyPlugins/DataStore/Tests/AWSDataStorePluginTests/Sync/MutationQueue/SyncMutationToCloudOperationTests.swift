//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import XCTest
import Combine

@testable import Amplify
@testable import AmplifyTestCommon
@testable import AWSPluginsCore
@testable import AWSDataStorePlugin

class SyncMutationToCloudOperationTests: XCTestCase {
    let defaultAsyncWaitTimeout = 2.0
    let secondsInADay = 60 * 60 * 24
    var mockAPIPlugin: MockAPICategoryPlugin!

    var reachabilityPublisher: CurrentValueSubject<ReachabilityUpdate, Never>!
    var publisher: AnyPublisher<ReachabilityUpdate, Never> {
        return reachabilityPublisher.eraseToAnyPublisher()
    }

    override func setUp() async throws {
        reachabilityPublisher = CurrentValueSubject<ReachabilityUpdate, Never>(ReachabilityUpdate(isOnline: false))
        await tryOrFail {
            try await setUpWithAPI()
        }
        ModelRegistry.register(modelType: Post.self)
        ModelRegistry.register(modelType: Comment.self)
    }

    func testRetryOnTimeoutOfWaiting() async throws {
        let expectMutationRequestCompletion = expectation(description: "Expect to complete mutation request")
        let expectFirstCallToAPIMutate = expectation(description: "First call to API.mutate")
        let expectSecondCallToAPIMutate = expectation(description: "Second call to API.mutate")

        let model = MockSynced(id: "id-1")
        let post1 = Post(title: "post1", content: "content1", createdAt: .now())
        let mutationEvent = try MutationEvent(model: post1, modelSchema: post1.schema, mutationType: .create)

        var numberOfTimesEntered = 0
        let responder = MutateRequestResponder<MutationSync<AnyModel>> { request in
            defer { numberOfTimesEntered += 1 }
            if numberOfTimesEntered == 0 {
                let requestInputVersion = request.variables.flatMap { $0["input"] as? [String: Any] }.flatMap { $0["_version"] as? Int }
                XCTAssertEqual(requestInputVersion, 10)
                expectFirstCallToAPIMutate.fulfill()
                let urlError = URLError(URLError.notConnectedToInternet)
                return .failure(.unknown("", "", APIError.networkError("mock NotConnectedToInternetError", nil, urlError)))
            } else if numberOfTimesEntered == 1, let anyModel = try? model.eraseToAnyModel() {
                expectSecondCallToAPIMutate.fulfill()
                let remoteSyncMetadata = MutationSyncMetadata(modelId: model.id,
                                                              modelName: model.modelName,
                                                              deleted: false,
                                                              lastChangedAt: Date().unixSeconds,
                                                              version: 2)
                return .success(MutationSync(model: anyModel, syncMetadata: remoteSyncMetadata))
            } else {
                XCTFail("This should not be called more than once")
                return .failure(.unknown("Unexpected operation", "", nil))
            }
        }
        mockAPIPlugin.responders[.mutateRequestResponse] = responder

        let completion: GraphQLOperation<MutationSync<AnyModel>>.ResultListener = { _ in
            expectMutationRequestCompletion.fulfill()
        }

        let operation = await SyncMutationToCloudOperation(
            mutationEvent: mutationEvent,
            getLatestSyncMetadata: {
                MutationSyncMetadata(
                    modelId: model.id,
                    modelName: model.modelName,
                    deleted: false,
                    lastChangedAt: Date().unixSeconds,
                    version: 10
                )
            },
            api: mockAPIPlugin,
            authModeStrategy: AWSDefaultAuthModeStrategy(),
            networkReachabilityPublisher: publisher,
            currentAttemptNumber: 1,
            completion: completion
        )
        let queue = OperationQueue()
        queue.addOperation(operation)
        await fulfillment(of: [
            expectFirstCallToAPIMutate,
            expectSecondCallToAPIMutate,
            expectMutationRequestCompletion
        ], timeout: defaultAsyncWaitTimeout)
    }

    func testRetryOnChangeReachability() async throws {
        let mockRequestRetryPolicy = MockRequestRetryablePolicy()
        let waitForeverToRetry = RequestRetryAdvice(shouldRetry: true, retryInterval: .seconds(secondsInADay))
        mockRequestRetryPolicy.pushOnRetryRequestAdvice(response: waitForeverToRetry)

        let expectMutationRequestCompletion = expectation(description: "Expect to complete mutation request")
        let expectFirstCallToAPIMutate = expectation(description: "First call to API.mutate")
        let expectSecondCallToAPIMutate = expectation(description: "Second call to API.mutate")
        let post1 = Post(title: "post1", content: "content1", createdAt: .now())
        let mutationEvent = try MutationEvent(model: post1, modelSchema: post1.schema, mutationType: .create)
        let model = MockSynced(id: "id-1")

        var numberOfTimesEntered = 0
        let responder = MutateRequestResponder<MutationSync<AnyModel>> { request in
            defer { numberOfTimesEntered += 1 }
            if numberOfTimesEntered == 0 {
                expectFirstCallToAPIMutate.fulfill()
                let urlError = URLError(URLError.notConnectedToInternet)
                return .failure(.unknown("", "", APIError.networkError("mock NotConnectedToInternetError", nil, urlError)))
            } else if numberOfTimesEntered == 1, let anyModel = try? model.eraseToAnyModel() {
                expectSecondCallToAPIMutate.fulfill()
                let remoteSyncMetadata = MutationSyncMetadata(modelId: model.id,
                                                              modelName: model.modelName,
                                                              deleted: false,
                                                              lastChangedAt: Date().unixSeconds,
                                                              version: 2)
                let remoteMutationSync = MutationSync(model: anyModel, syncMetadata: remoteSyncMetadata)
                return .success(remoteMutationSync)
            } else {
                XCTFail("This should not be called more than once")
                return .failure(.unknown("This should not be called more than once", "", nil))
            }
        }
        mockAPIPlugin.responders[.mutateRequestResponse] = responder

        let completion: GraphQLOperation<MutationSync<AnyModel>>.ResultListener = { _ in
            expectMutationRequestCompletion.fulfill()
        }
        let operation = await SyncMutationToCloudOperation(
            mutationEvent: mutationEvent,
            getLatestSyncMetadata: { nil },
            api: mockAPIPlugin,
            authModeStrategy: AWSDefaultAuthModeStrategy(),
            networkReachabilityPublisher: publisher,
            currentAttemptNumber: 1,
            requestRetryablePolicy: mockRequestRetryPolicy,
            completion: completion
        )
        let queue = OperationQueue()
        queue.addOperation(operation)
        await fulfillment(of: [expectFirstCallToAPIMutate], timeout: defaultAsyncWaitTimeout)

        reachabilityPublisher.send(ReachabilityUpdate(isOnline: true))

        await fulfillment(of: [expectSecondCallToAPIMutate], timeout: defaultAsyncWaitTimeout)
        await fulfillment(of: [expectMutationRequestCompletion], timeout: defaultAsyncWaitTimeout)
    }

    func testAbilityToCancel() async throws {
        let mockRequestRetryPolicy = MockRequestRetryablePolicy()
        let waitForeverToRetry = RequestRetryAdvice(shouldRetry: true, retryInterval: .seconds(secondsInADay))
        mockRequestRetryPolicy.pushOnRetryRequestAdvice(response: waitForeverToRetry)

        let expectMutationRequestFailed = expectation(description: "Expect to fail mutation request")
        let expectFirstCallToAPIMutate = expectation(description: "First call to API.mutate")
        let post1 = Post(title: "post1", content: "content1", createdAt: .now())
        let mutationEvent = try MutationEvent(model: post1, modelSchema: post1.schema, mutationType: .create)

        var numberOfTimesEntered = 0
        let responder = MutateRequestResponder<MutationSync<AnyModel>> { _ in
            defer { numberOfTimesEntered += 1 }
            if numberOfTimesEntered == 0 {
                expectFirstCallToAPIMutate.fulfill()
                let urlError = URLError(URLError.notConnectedToInternet)
                return .failure(.unknown("", "", APIError.networkError("mock NotConnectedToInternetError", nil, urlError)))
            } else {
                XCTFail("This should not be called more than once")
                return .failure(.unknown("This should not be called more than once", "", nil))
            }

        }
        mockAPIPlugin.responders[.mutateRequestResponse] = responder

        let completion: GraphQLOperation<MutationSync<AnyModel>>.ResultListener = { asyncEvent in
            switch asyncEvent {
            case .failure:
                expectMutationRequestFailed.fulfill()
            default:
                break
            }
        }
        let operation = await SyncMutationToCloudOperation(
            mutationEvent: mutationEvent,
            getLatestSyncMetadata: { nil },
            api: mockAPIPlugin,
            authModeStrategy: AWSDefaultAuthModeStrategy(),
            networkReachabilityPublisher: publisher,
            currentAttemptNumber: 1,
            requestRetryablePolicy: mockRequestRetryPolicy,
            completion: completion
        )
        let queue = OperationQueue()
        queue.addOperation(operation)
        await fulfillment(of: [expectFirstCallToAPIMutate], timeout: defaultAsyncWaitTimeout)

        // At this point, we will be "waiting forever" to retry our request or until the operation is canceled
        operation.cancel()
        await fulfillment(of: [expectMutationRequestFailed], timeout: defaultAsyncWaitTimeout)
    }
    
    // MARK: - GetRetryAdviceIfRetryableTests
    
    func testGetRetryAdvice_NetworkError_RetryTrue() async throws {
        let operation = await SyncMutationToCloudOperation(
            mutationEvent: try createMutationEvent(),
            getLatestSyncMetadata: { nil },
            api: mockAPIPlugin,
            authModeStrategy: AWSDefaultAuthModeStrategy(),
            networkReachabilityPublisher: publisher,
            currentAttemptNumber: 1,
            completion: { _ in }
        )
        
        let error = APIError.networkError("", nil, URLError(.userAuthenticationRequired))
        let advice = operation.getRetryAdviceIfRetryable(error: error)
        XCTAssertTrue(advice.shouldRetry)
    }
    
    func testGetRetryAdvice_HTTPStatusError401WithMultiAuth_RetryTrue() async throws {
        let operation = await SyncMutationToCloudOperation(
            mutationEvent: try createMutationEvent(),
            getLatestSyncMetadata: { nil },
            api: mockAPIPlugin,
            authModeStrategy: MockMultiAuthModeStrategy(),
            networkReachabilityPublisher: publisher,
            currentAttemptNumber: 1,
            completion: { _ in }
        )
        let response = HTTPURLResponse(url: URL(string: "http://localhost")!,
                                       statusCode: 401,
                                       httpVersion: nil,
                                       headerFields: nil)!
        let error = APIError.httpStatusError(401, response)
        let advice = operation.getRetryAdviceIfRetryable(error: error)
        XCTAssertTrue(advice.shouldRetry)
    }
    
    /// Given: Model with multiple auth types. Mutation requests always fail with 401 error code
    /// When: Mutating model fails with 401
    /// Then: DataStore will try again with each auth type and eventually fails
    func testGetRetryAdviceForEachModelAuthTypeThenFail_HTTPStatusError401() async throws {
        var numberOfTimesEntered = 0
        let mutationEvent = try createMutationEvent()
        let authStrategy = MockMultiAuthModeStrategy()
        let expectedNumberOfTimesEntered = authStrategy.authTypesFor(schema: mutationEvent.schema, operation: .create).count
        
        let expectCalllToApiMutateNTimesAndFail = expectation(description: "Call API.mutate \(expectedNumberOfTimesEntered) times and then fail")
        
        let response = HTTPURLResponse(url: URL(string: "http://localhost")!,
                                       statusCode: 401,
                                       httpVersion: nil,
                                       headerFields: nil)!
        let error = APIError.httpStatusError(401, response)
        
        let operation = await SyncMutationToCloudOperation(
            mutationEvent: mutationEvent,
            getLatestSyncMetadata: { nil },
            api: mockAPIPlugin,
            authModeStrategy: authStrategy,
            networkReachabilityPublisher: publisher,
            currentAttemptNumber: 1,
            completion: { result in
                if numberOfTimesEntered == expectedNumberOfTimesEntered {
                    expectCalllToApiMutateNTimesAndFail.fulfill()
                    
                } else {
                    XCTFail("API.mutate was called incorrect amount of times, expected: \(expectedNumberOfTimesEntered), was : \(numberOfTimesEntered)")
                }
            }
        )
        
        let responder = MutateRequestResponder<MutationSync<AnyModel>> { request in
            defer { numberOfTimesEntered += 1 }
            return .failure(.unknown("", "", error))
        }
        
        mockAPIPlugin.responders[.mutateRequestResponse] = responder

        let queue = OperationQueue()
        queue.addOperation(operation)
        
        await fulfillment(of: [expectCalllToApiMutateNTimesAndFail], timeout: defaultAsyncWaitTimeout)
    }
    
    func testGetRetryAdvice_OperationErrorAuthErrorWithMultiAuth_RetryTrue() async throws {
        let operation = await SyncMutationToCloudOperation(
            mutationEvent: try createMutationEvent(),
            getLatestSyncMetadata: { nil },
            api: mockAPIPlugin,
            authModeStrategy: MockMultiAuthModeStrategy(),
            networkReachabilityPublisher: publisher,
            currentAttemptNumber: 1,
            completion: { _ in }
        )
        
        let authError = AuthError.notAuthorized("", "", nil)
        let error = APIError.operationError("", "", authError)
        let advice = operation.getRetryAdviceIfRetryable(error: error)
        XCTAssertTrue(advice.shouldRetry)
    }
    
    func testGetRetryAdvice_OperationErrorAuthErrorWithSingleAuth_RetryFalse() async throws {
        let expectation = expectation(description: "operation completed")
        var numberOfTimesEntered = 0
        var error: APIError?
        let operation = await SyncMutationToCloudOperation(
            mutationEvent: try createMutationEvent(),
            getLatestSyncMetadata: { nil },
            api: mockAPIPlugin,
            authModeStrategy: AWSDefaultAuthModeStrategy(),
            networkReachabilityPublisher: publisher,
            currentAttemptNumber: 1,
            completion: { result in
                XCTAssertEqual(numberOfTimesEntered, 1)
                switch result {
                case .failure(let apiError):
                    error = apiError
                default:
                    XCTFail("Wrong result")
                }
                expectation.fulfill()
            }
        )

        let responder = MutateRequestResponder<MutationSync<AnyModel>> { request in
            defer { numberOfTimesEntered += 1 }
            let authError = AuthError.notAuthorized("", "", nil)
            return .failure(.unknown("", "", APIError.operationError("", "", authError)))
        }

        mockAPIPlugin.responders[.mutateRequestResponse] = responder

        let queue = OperationQueue()
        queue.addOperation(operation)
        await fulfillment(of: [expectation])
        XCTAssertEqual(false, operation.getRetryAdviceIfRetryable(error: error!).shouldRetry)
    }
    
    func testGetRetryAdvice_OperationErrorAuthErrorSessionExpired_RetryTrue() async throws {
        let operation = await SyncMutationToCloudOperation(
            mutationEvent: try createMutationEvent(),
            getLatestSyncMetadata: { nil },
            api: mockAPIPlugin,
            authModeStrategy: AWSDefaultAuthModeStrategy(),
            networkReachabilityPublisher: publisher,
            currentAttemptNumber: 1,
            completion: { _ in }
        )
        
        let authError = AuthError.sessionExpired("", "", nil)
        let error = APIError.operationError("", "", authError)
        let advice = operation.getRetryAdviceIfRetryable(error: error)
        XCTAssertTrue(advice.shouldRetry)
    }
    
    func testGetRetryAdvice_OperationErrorAuthErrorSignedOut_RetryTrue() async throws {
        let operation = await SyncMutationToCloudOperation(
            mutationEvent: try createMutationEvent(),
            getLatestSyncMetadata: { nil },
            api: mockAPIPlugin,
            authModeStrategy: AWSDefaultAuthModeStrategy(),
            networkReachabilityPublisher: publisher,
            currentAttemptNumber: 1,
            completion: { _ in }
        )
        
        let authError = AuthError.signedOut("", "", nil)
        let error = APIError.operationError("", "", authError)
        let advice = operation.getRetryAdviceIfRetryable(error: error)
        XCTAssertTrue(advice.shouldRetry)
    }
    
    private func createMutationEvent() throws -> MutationEvent {
        let post1 = Post(title: "post1", content: "content1", createdAt: .now())
        return try MutationEvent(model: post1, modelSchema: post1.schema, mutationType: .create)
    }
    
}

public class MockMultiAuthModeStrategy: AuthModeStrategy {
    public weak var authDelegate: AuthModeStrategyDelegate?
    required public init() {}

    public func authTypesFor(schema: ModelSchema,
                             operation: ModelOperation) -> AWSAuthorizationTypeIterator {
        return AWSAuthorizationTypeIterator(withValues: [
            .designated(.amazonCognitoUserPools),
            .designated(.apiKey)
        ])
    }

    public func authTypesFor(schema: ModelSchema,
                             operations: [ModelOperation]) -> AWSAuthorizationTypeIterator {
        return AWSAuthorizationTypeIterator(withValues: [
            .designated(.amazonCognitoUserPools),
            .designated(.apiKey)
        ])
    }
}

extension SyncMutationToCloudOperationTests {
    private func setUpCore() async throws -> AmplifyConfiguration {
        await Amplify.reset()

        let dataStorePublisher = DataStorePublisher()
        let dataStorePlugin = AWSDataStorePlugin(modelRegistration: TestModelRegistration(),
                                                 storageEngineBehaviorFactory: MockStorageEngineBehavior.mockStorageEngineBehaviorFactory,
                                                 dataStorePublisher: dataStorePublisher,
                                                 validAPIPluginKey: "MockAPICategoryPlugin",
                                                 validAuthPluginKey: "MockAuthCategoryPlugin")

        try Amplify.add(plugin: dataStorePlugin)
        let dataStoreConfig = DataStoreCategoryConfiguration(plugins: [
            "awsDataStorePlugin": true
        ])

        let amplifyConfig = AmplifyConfiguration(dataStore: dataStoreConfig)

        return amplifyConfig
    }

    private func setUpAPICategory(config: AmplifyConfiguration) throws -> AmplifyConfiguration {
        mockAPIPlugin = MockAPICategoryPlugin()
        try Amplify.add(plugin: mockAPIPlugin)

        let apiConfig = APICategoryConfiguration(plugins: [
            "MockAPICategoryPlugin": true
        ])
        let amplifyConfig = AmplifyConfiguration(api: apiConfig, dataStore: config.dataStore)
        return amplifyConfig
    }

    private func setUpWithAPI() async throws {
        let configWithoutAPI = try await setUpCore()
        let configWithAPI = try setUpAPICategory(config: configWithoutAPI)
        try Amplify.configure(configWithAPI)
    }
}
