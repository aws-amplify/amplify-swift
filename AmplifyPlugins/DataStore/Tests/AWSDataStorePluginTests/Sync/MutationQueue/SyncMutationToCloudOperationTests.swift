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

        let post1 = Post(title: "post1", content: "content1", createdAt: .now())
        let mutationEvent = try MutationEvent(model: post1, modelSchema: post1.schema, mutationType: .create)

        var listenerFromFirstRequestOptional: GraphQLOperation<MutationSync<AnyModel>>.ResultListener?
        var listenerFromSecondRequestOptional: GraphQLOperation<MutationSync<AnyModel>>.ResultListener?

        var numberOfTimesEntered = 0
        let responder = { _, eventListener in
            if numberOfTimesEntered == 0 {
                listenerFromFirstRequestOptional = eventListener
                expectFirstCallToAPIMutate.fulfill()
            } else if numberOfTimesEntered == 1 {
                listenerFromSecondRequestOptional = eventListener
                expectSecondCallToAPIMutate.fulfill()
            } else {
                XCTFail("This should not be called more than once")
            }
            numberOfTimesEntered += 1
            // We could return an operation here, but we don't need to.
            // The main reason for having this responder is to get the eventListener.
            // the eventListener block will execute the the call to validateResponseFromCloud
            return nil
        } as MutateRequestListenerResponder<MutationSync<AnyModel>>

        mockAPIPlugin.responders[.mutateRequestListener] = responder

        let completion: GraphQLOperation<MutationSync<AnyModel>>.ResultListener = { _ in
            expectMutationRequestCompletion.fulfill()
        }

        let operation = await SyncMutationToCloudOperation(mutationEvent: mutationEvent,
                                                     api: mockAPIPlugin,
                                                     authModeStrategy: AWSDefaultAuthModeStrategy(),
                                                     networkReachabilityPublisher: publisher,
                                                     currentAttemptNumber: 1,
                                                     completion: completion)
        let queue = OperationQueue()
        queue.addOperation(operation)
        wait(for: [expectFirstCallToAPIMutate], timeout: defaultAsyncWaitTimeout)
        guard let listenerFromFirstRequest = listenerFromFirstRequestOptional else {
            XCTFail("Listener was not called through MockAPICategoryPlugin")
            return
        }

        let urlError = URLError(URLError.notConnectedToInternet)
        listenerFromFirstRequest(.failure(APIError.networkError("mock NotConnectedToInternetError", nil, urlError)))
        wait(for: [expectSecondCallToAPIMutate], timeout: defaultAsyncWaitTimeout)

        guard let listenerFromSecondRequest = listenerFromSecondRequestOptional else {
            XCTFail("Listener was not called through MockAPICategoryPlugin")
            return
        }

        let model = MockSynced(id: "id-1")
        let anyModel = try model.eraseToAnyModel()
        let remoteSyncMetadata = MutationSyncMetadata(modelId: model.id,
                                                      modelName: model.modelName,
                                                      deleted: false,
                                                      lastChangedAt: Date().unixSeconds,
                                                      version: 2)
        let remoteMutationSync = MutationSync(model: anyModel, syncMetadata: remoteSyncMetadata)
        listenerFromSecondRequest(.success(.success(remoteMutationSync)))
        // waitForExpectations(timeout: 1)
        wait(for: [expectMutationRequestCompletion], timeout: defaultAsyncWaitTimeout)
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

        var listenerFromFirstRequestOptional: GraphQLOperation<MutationSync<AnyModel>>.ResultListener?
        var listenerFromSecondRequestOptional: GraphQLOperation<MutationSync<AnyModel>>.ResultListener?

        var numberOfTimesEntered = 0
        let responder = { _, eventListener in
            if numberOfTimesEntered == 0 {
                listenerFromFirstRequestOptional = eventListener
                expectFirstCallToAPIMutate.fulfill()
            } else if numberOfTimesEntered == 1 {
                listenerFromSecondRequestOptional = eventListener
                expectSecondCallToAPIMutate.fulfill()
            } else {
                XCTFail("This should not be called more than once")
            }
            numberOfTimesEntered += 1
            // We could return an operation here, but we don't need to.
            // The main reason for having this responder is to get the eventListener.
            // the eventListener block will execute the the call to validateResponseFromCloud
            return nil
        } as MutateRequestListenerResponder<MutationSync<AnyModel>>

        mockAPIPlugin.responders[.mutateRequestListener] = responder

        let completion: GraphQLOperation<MutationSync<AnyModel>>.ResultListener = { _ in
            expectMutationRequestCompletion.fulfill()
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
        wait(for: [expectFirstCallToAPIMutate], timeout: defaultAsyncWaitTimeout)
        guard let listenerFromFirstRequest = listenerFromFirstRequestOptional else {
            XCTFail("Listener was not called through MockAPICategoryPlugin")
            return
        }

        let urlError = URLError(URLError.notConnectedToInternet)
        listenerFromFirstRequest(.failure(APIError.networkError("mock NotConnectedToInternetError", nil, urlError)))
        reachabilityPublisher.send(ReachabilityUpdate(isOnline: true))

        wait(for: [expectSecondCallToAPIMutate], timeout: defaultAsyncWaitTimeout)
        guard let listenerFromSecondRequest = listenerFromSecondRequestOptional else {
            XCTFail("Listener was not called through MockAPICategoryPlugin")
            return
        }

        let model = MockSynced(id: "id-1")
        let anyModel = try model.eraseToAnyModel()
        let remoteSyncMetadata = MutationSyncMetadata(modelId: model.id,
                                                      modelName: model.modelName,
                                                      deleted: false,
                                                      lastChangedAt: Date().unixSeconds,
                                                      version: 2)
        let remoteMutationSync = MutationSync(model: anyModel, syncMetadata: remoteSyncMetadata)
        listenerFromSecondRequest(.success(.success(remoteMutationSync)))
        wait(for: [expectMutationRequestCompletion], timeout: defaultAsyncWaitTimeout)
    }

    func testAbilityToCancel() async throws {
        let mockRequestRetryPolicy = MockRequestRetryablePolicy()
        let waitForeverToRetry = RequestRetryAdvice(shouldRetry: true, retryInterval: .seconds(secondsInADay))
        mockRequestRetryPolicy.pushOnRetryRequestAdvice(response: waitForeverToRetry)

        let expectMutationRequestFailed = expectation(description: "Expect to fail mutation request")
        let expectFirstCallToAPIMutate = expectation(description: "First call to API.mutate")
        let post1 = Post(title: "post1", content: "content1", createdAt: .now())
        let mutationEvent = try MutationEvent(model: post1, modelSchema: post1.schema, mutationType: .create)

        var listenerFromFirstRequestOptional: GraphQLOperation<MutationSync<AnyModel>>.ResultListener?

        var numberOfTimesEntered = 0
        let responder = { _, eventListener in
            if numberOfTimesEntered == 0 {
                listenerFromFirstRequestOptional = eventListener
                expectFirstCallToAPIMutate.fulfill()
            } else {
                XCTFail("This should not be called more than once")
            }
            numberOfTimesEntered += 1
            // We could return an operation here, but we don't need to.
            // The main reason for having this responder is to get the eventListener.
            // the eventListener block will execute the the call to validateResponseFromCloud
            return nil
        } as MutateRequestListenerResponder<MutationSync<AnyModel>>
        
        mockAPIPlugin.responders[.mutateRequestListener] = responder

        let completion: GraphQLOperation<MutationSync<AnyModel>>.ResultListener = { asyncEvent in
            switch asyncEvent {
            case .failure:
                expectMutationRequestFailed.fulfill()
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
        wait(for: [expectFirstCallToAPIMutate], timeout: defaultAsyncWaitTimeout)
        guard let listenerFromFirstRequest = listenerFromFirstRequestOptional else {
            XCTFail("Listener was not called through MockAPICategoryPlugin")
            return
        }

        let urlError = URLError(URLError.notConnectedToInternet)
        listenerFromFirstRequest(.failure(APIError.networkError("mock NotConnectedToInternetError", nil, urlError)))

        // At this point, we will be "waiting forever" to retry our request or until the operation is canceled
        operation.cancel()
        wait(for: [expectMutationRequestFailed], timeout: defaultAsyncWaitTimeout)
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
