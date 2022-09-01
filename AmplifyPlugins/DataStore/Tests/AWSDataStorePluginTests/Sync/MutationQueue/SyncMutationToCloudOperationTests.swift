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
        let expectMutationRequestCompletion = asyncExpectation(description: "Expect to complete mutation request")
        let expectFirstCallToAPIMutate = asyncExpectation(description: "First call to API.mutate")
        let expectSecondCallToAPIMutate = asyncExpectation(description: "Second call to API.mutate")
        
        let post1 = Post(title: "post1", content: "content1", createdAt: .now())
        let mutationEvent = try MutationEvent(model: post1, modelSchema: post1.schema, mutationType: .create)

        let urlError = URLError(URLError.notConnectedToInternet)
        let networkError = APIError.networkError("mock NotConnectedToInternetError", nil, urlError)
        
        let model = MockSynced(id: "id-1")
        let anyModel = try model.eraseToAnyModel()
        let remoteSyncMetadata = MutationSyncMetadata(modelId: model.id,
                                                      modelName: model.modelName,
                                                      deleted: false,
                                                      lastChangedAt: Date().unixSeconds,
                                                      version: 2)
        let remoteMutationSync = MutationSync(model: anyModel, syncMetadata: remoteSyncMetadata)
        
        var numberOfTimesEntered = 0
        let responder = MutateRequestResponder<MutationSync<AnyModel>> { _ in
            if numberOfTimesEntered == 0 {
                numberOfTimesEntered += 1
                Task { await expectFirstCallToAPIMutate.fulfill() }
                return .failure(networkError)
            } else if numberOfTimesEntered == 1 {
                numberOfTimesEntered += 1
                Task { await expectSecondCallToAPIMutate.fulfill() }
                return .success(.success(remoteMutationSync))
            } else {
                XCTFail("This should not be called more than twice")
            }
            
            return .failure(.unknown("This shouldn't called", "", nil))
        }
        mockAPIPlugin.responders[.mutateRequestResponse] = responder

        let completion: GraphQLOperation<MutationSync<AnyModel>>.ResultListener = { _ in
            Task { await expectMutationRequestCompletion.fulfill() }
        }

        let operation = await SyncMutationToCloudOperation(mutationEvent: mutationEvent,
                                                           api: mockAPIPlugin,
                                                           authModeStrategy: AWSDefaultAuthModeStrategy(),
                                                           networkReachabilityPublisher: publisher,
                                                           currentAttemptNumber: 1,
                                                           completion: completion)
        let queue = OperationQueue()
        queue.addOperation(operation)
        
        await waitForExpectations([expectFirstCallToAPIMutate,
                                   expectSecondCallToAPIMutate,
                                   expectMutationRequestCompletion], timeout: defaultAsyncWaitTimeout)
    }

    func testRetryOnChangeReachability() async throws {
        let mockRequestRetryPolicy = MockRequestRetryablePolicy()
        let waitForeverToRetry = RequestRetryAdvice(shouldRetry: true, retryInterval: .seconds(secondsInADay))
        mockRequestRetryPolicy.pushOnRetryRequestAdvice(response: waitForeverToRetry)

        let expectMutationRequestCompletion = asyncExpectation(description: "Expect to complete mutation request")
        let expectFirstCallToAPIMutate = asyncExpectation(description: "First call to API.mutate")
        let expectSecondCallToAPIMutate = asyncExpectation(description: "Second call to API.mutate")
        
        let post1 = Post(title: "post1", content: "content1", createdAt: .now())
        let mutationEvent = try MutationEvent(model: post1, modelSchema: post1.schema, mutationType: .create)

        let urlError = URLError(URLError.notConnectedToInternet)
        let networkError = APIError.networkError("mock NotConnectedToInternetError", nil, urlError)
        
        let model = MockSynced(id: "id-1")
        let anyModel = try model.eraseToAnyModel()
        let remoteSyncMetadata = MutationSyncMetadata(modelId: model.id,
                                                      modelName: model.modelName,
                                                      deleted: false,
                                                      lastChangedAt: Date().unixSeconds,
                                                      version: 2)
        let remoteMutationSync = MutationSync(model: anyModel, syncMetadata: remoteSyncMetadata)
        

        var numberOfTimesEntered = 0
        let responder = MutateRequestResponder<MutationSync<AnyModel>> { _ in
            if numberOfTimesEntered == 0 {
                numberOfTimesEntered += 1
                // Queue up a reachability update, after sending back the network error
                Task {
                    try await Task.sleep(seconds: 1)
                    self.reachabilityPublisher.send(ReachabilityUpdate(isOnline: true))
                }
                Task { await expectFirstCallToAPIMutate.fulfill() }
                return .failure(networkError)
            } else if numberOfTimesEntered == 1 {
                numberOfTimesEntered += 1
                Task { await expectSecondCallToAPIMutate.fulfill() }
                return .success(.success(remoteMutationSync))
            } else {
                XCTFail("This should not be called more than twice")
            }
            
            return .failure(.unknown("This shouldn't called", "", nil))
        }
        mockAPIPlugin.responders[.mutateRequestResponse] = responder

        let completion: GraphQLOperation<MutationSync<AnyModel>>.ResultListener = { _ in
            Task { await expectMutationRequestCompletion.fulfill() }
        }
        let operation = await SyncMutationToCloudOperation(mutationEvent: mutationEvent,
                                                           api: mockAPIPlugin,
                                                           authModeStrategy: AWSDefaultAuthModeStrategy(),
                                                           networkReachabilityPublisher: publisher,
                                                           currentAttemptNumber: 1,
                                                           requestRetryablePolicy: mockRequestRetryPolicy,
                                                           completion: completion)
        let queue = OperationQueue()
        queue.addOperation(operation)
        
        await waitForExpectations([expectFirstCallToAPIMutate,
                                   expectSecondCallToAPIMutate,
                                   expectMutationRequestCompletion], timeout: defaultAsyncWaitTimeout)
    }

    func testAbilityToCancel() async throws {
        let mockRequestRetryPolicy = MockRequestRetryablePolicy()
        let waitForeverToRetry = RequestRetryAdvice(shouldRetry: true, retryInterval: .seconds(secondsInADay))
        mockRequestRetryPolicy.pushOnRetryRequestAdvice(response: waitForeverToRetry)

        let expectMutationRequestFailed = asyncExpectation(description: "Expect to fail mutation request")
        let expectFirstCallToAPIMutate = asyncExpectation(description: "First call to API.mutate")
        let post1 = Post(title: "post1", content: "content1", createdAt: .now())
        let mutationEvent = try MutationEvent(model: post1, modelSchema: post1.schema, mutationType: .create)

        let urlError = URLError(URLError.notConnectedToInternet)
        let networkError = APIError.networkError("mock NotConnectedToInternetError", nil, urlError)

        var numberOfTimesEntered = 0
        let responder = MutateRequestResponder<MutationSync<AnyModel>> { _ in
            if numberOfTimesEntered == 0 {
                numberOfTimesEntered += 1
                Task { await expectFirstCallToAPIMutate.fulfill() }
                return .failure(networkError)
            } else {
                XCTFail("This should not be called more than once")
            }
        
            return .failure(.unknown("This shouldn't called", "", nil))
        }
        mockAPIPlugin.responders[.mutateRequestResponse] = responder

        let completion: GraphQLOperation<MutationSync<AnyModel>>.ResultListener = { asyncEvent in
            switch asyncEvent {
            case .failure:
                Task { await expectMutationRequestFailed.fulfill() }
            default:
                break
            }
        }
        let operation = await SyncMutationToCloudOperation(mutationEvent: mutationEvent,
                                                     api: mockAPIPlugin,
                                                     authModeStrategy: AWSDefaultAuthModeStrategy(),
                                                     networkReachabilityPublisher: publisher,
                                                     currentAttemptNumber: 1,
                                                     requestRetryablePolicy: mockRequestRetryPolicy,
                                                     completion: completion)
        let queue = OperationQueue()
        queue.addOperation(operation)
        await waitForExpectations([expectFirstCallToAPIMutate], timeout: defaultAsyncWaitTimeout)

        // At this point, we will be "waiting forever" to retry our request or until the operation is canceled
        operation.cancel()
        await waitForExpectations([expectMutationRequestFailed], timeout: defaultAsyncWaitTimeout)
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
