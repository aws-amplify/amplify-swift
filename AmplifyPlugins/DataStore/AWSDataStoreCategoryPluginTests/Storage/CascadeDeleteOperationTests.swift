//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
import SQLite
import Combine

@testable import Amplify
@testable import AmplifyTestCommon
@testable import AWSDataStorePlugin

// swiftlint:disable type_body_length
class CascadeDeleteOperationTests: StorageEngineTestsBase {

    override func setUp() {
        super.setUp()
        Amplify.Logging.logLevel = .warn

        let validAPIPluginKey = "MockAPICategoryPlugin"
        let validAuthPluginKey = "MockAuthCategoryPlugin"
        do {
            connection = try Connection(.inMemory)
            storageAdapter = try SQLiteStorageEngineAdapter(connection: connection)
            try storageAdapter.setUp(modelSchemas: StorageEngine.systemModelSchemas)

            syncEngine = MockRemoteSyncEngine()
            storageEngine = StorageEngine(storageAdapter: storageAdapter,
                                          dataStoreConfiguration: .default,
                                          syncEngine: syncEngine,
                                          validAPIPluginKey: validAPIPluginKey,
                                          validAuthPluginKey: validAuthPluginKey)
            ModelRegistry.register(modelType: Restaurant.self)
            ModelRegistry.register(modelType: Menu.self)
            ModelRegistry.register(modelType: Dish.self)
            ModelRegistry.register(modelType: ModelCompositePk.self)
            ModelRegistry.register(modelType: PostWithCompositeKey.self)
            ModelRegistry.register(modelType: CommentWithCompositeKey.self)
            do {
                try storageEngine.setUp(modelSchemas: [Restaurant.schema])
                try storageEngine.setUp(modelSchemas: [Menu.schema])
                try storageEngine.setUp(modelSchemas: [Dish.schema])
                try storageEngine.setUp(modelSchemas: [ModelCompositePk.schema])
                try storageEngine.setUp(modelSchemas: [PostWithCompositeKey.schema])
                try storageEngine.setUp(modelSchemas: [CommentWithCompositeKey.schema])

            } catch {
                XCTFail("Failed to setup storage engine")
            }
        } catch {
            XCTFail(String(describing: error))
            return
        }
    }

    // MARK: - Query and delete (No Sync)

    func testWithId() {
        let restaurant = Restaurant(restaurantName: "restaurant1")
        guard case .success = saveModelSynchronous(model: restaurant) else {
            XCTFail("Failed to save")
            return
        }
        let predicate: QueryPredicate = Restaurant.keys.id == restaurant.id
        guard case .success(let queriedRestaurants) = queryModelSynchronous(modelType: Restaurant.self,
                                                                            predicate: predicate) else {
            XCTFail("Failed to query")
            return
        }
        XCTAssertEqual(queriedRestaurants.count, 1)
        let completed = expectation(description: "operation completed")
        let identifier = DefaultModelIdentifier<Restaurant>.makeDefault(id: restaurant.id)
        let operation = CascadeDeleteOperation(storageAdapter: storageAdapter,
                                               syncEngine: nil,
                                               modelType: Restaurant.self,
                                               modelSchema: Restaurant.schema,
                                               withIdentifier: identifier) { result in
            switch result {
            case .success(let restaurant):
                XCTAssertNotNil(restaurant)
                completed.fulfill()
            case .failure(let error):
                XCTFail("\(error)")
            }
        }
        operation.start()
        wait(for: [completed], timeout: 1)
        guard case .success(let queriedRestaurants) = queryModelSynchronous(modelType: Restaurant.self,
                                                                            predicate: predicate) else {
            XCTFail("Failed to query")
            return
        }
        XCTAssertEqual(queriedRestaurants.count, 0)
    }

    func testWithCompositeIdentifier() {
        let modelId = "model-id"
        let modelDob = Temporal.DateTime.now()
        let model = ModelCompositePk(id: modelId, dob: modelDob, name: "name")
        guard case .success = saveModelSynchronous(model: model) else {
            XCTFail("Failed to save")
            return
        }
        let predicate: QueryPredicate = ModelCompositePk.keys.id == modelId
            && ModelCompositePk.keys.dob == modelDob
        guard case .success(let queriedModel) = queryModelSynchronous(modelType: ModelCompositePk.self,
                                                                            predicate: predicate) else {
            XCTFail("Failed to query")
            return
        }
        XCTAssertEqual(queriedModel.count, 1)
        XCTAssertEqual(queriedModel[0].id, model.id)
        XCTAssertEqual(queriedModel[0].name, model.name)
        XCTAssertEqual(queriedModel[0].dob, model.dob)

        let completed = expectation(description: "operation completed")
        let identifier = ModelCompositePk.Identifier.identifier(id: modelId, dob: modelDob)
        let operation = CascadeDeleteOperation(storageAdapter: storageAdapter,
                                               syncEngine: nil,
                                               modelType: ModelCompositePk.self,
                                               modelSchema: ModelCompositePk.schema,
                                               withIdentifier: identifier) { result in
            switch result {
            case .success(let model):
                XCTAssertNotNil(model)
                completed.fulfill()
            case .failure(let error):
                XCTFail("\(error)")
            }
        }
        operation.start()
        wait(for: [completed], timeout: 1)
        guard case .success(let queriedModel) = queryModelSynchronous(modelType: ModelCompositePk.self,
                                                                            predicate: predicate) else {
            XCTFail("Failed to query")
            return
        }
        XCTAssertEqual(queriedModel.count, 0)
    }

    func testWithIdAndCondition() {
        let restaurantName = UUID().uuidString
        let restaurant = Restaurant(restaurantName: restaurantName)
        guard case .success = saveModelSynchronous(model: restaurant) else {
            XCTFail("Failed to save")
            return
        }
        let predicate: QueryPredicate = Restaurant.keys.id == restaurant.id &&
            Restaurant.keys.restaurantName == restaurantName
        guard case .success(let queriedRestaurants) = queryModelSynchronous(modelType: Restaurant.self,
                                                                            predicate: predicate) else {
            XCTFail("Failed to query")
            return
        }
        XCTAssertEqual(queriedRestaurants.count, 1)
        XCTAssertEqual(queriedRestaurants.first!.restaurantName, restaurantName)
        let completed = expectation(description: "operation completed")
        let identifier = DefaultModelIdentifier<Restaurant>.makeDefault(id: restaurant.id)
        let operation = CascadeDeleteOperation(storageAdapter: storageAdapter,
                                               syncEngine: nil,
                                               modelType: Restaurant.self,
                                               modelSchema: Restaurant.schema,
                                               withIdentifier: identifier,
                                               condition: Restaurant.keys.restaurantName.eq(restaurantName)) { result in
            switch result {
            case .success(let restaurant):
                XCTAssertNotNil(restaurant)
                completed.fulfill()
            case .failure(let error):
                XCTFail("\(error)")
            }
        }
        operation.start()
        wait(for: [completed], timeout: 1)
        guard case .success(let queriedRestaurants) = queryModelSynchronous(modelType: Restaurant.self,
                                                                            predicate: predicate) else {
            XCTFail("Failed to query")
            return
        }
        XCTAssertEqual(queriedRestaurants.count, 0)
    }

    func testWithIdAndCondition_InvalidCondition() {
        let restaurantName = UUID().uuidString
        let restaurant = Restaurant(restaurantName: restaurantName)
        guard case .success = saveModelSynchronous(model: restaurant) else {
            XCTFail("Failed to save")
            return
        }
        let predicate: QueryPredicate = Restaurant.keys.id == restaurant.id &&
            Restaurant.keys.restaurantName == restaurantName
        guard case .success(let queriedRestaurants) = queryModelSynchronous(modelType: Restaurant.self,
                                                                            predicate: predicate) else {
            XCTFail("Failed to query")
            return
        }
        XCTAssertEqual(queriedRestaurants.count, 1)
        XCTAssertEqual(queriedRestaurants.first!.restaurantName, restaurantName)
        let completed = expectation(description: "operation completed")
        let identifier = DefaultModelIdentifier<Restaurant>.makeDefault(id: restaurant.id)
        let operation = CascadeDeleteOperation(storageAdapter: storageAdapter,
                                               syncEngine: nil,
                                               modelType: Restaurant.self,
                                               modelSchema: Restaurant.schema,
                                               withIdentifier: identifier,
                                               condition: Restaurant.keys.restaurantName.ne(restaurantName)) { result in
            switch result {
            case .success:
                XCTFail("Should have been invalid condition error")
            case .failure(let error):
                guard case .invalidCondition = error else {
                    XCTFail("\(error)")
                    return
                }
                completed.fulfill()
            }
        }
        operation.start()
        wait(for: [completed], timeout: 1)
        guard case .success(let queriedRestaurants) = queryModelSynchronous(modelType: Restaurant.self,
                                                                            predicate: predicate) else {
            XCTFail("Failed to query")
            return
        }
        XCTAssertEqual(queriedRestaurants.count, 1)
        XCTAssertEqual(queriedRestaurants[0].restaurantName, restaurantName)
    }

    func testWithFilter() {
        let restaurantName = UUID().uuidString
        let restaurant = Restaurant(restaurantName: restaurantName)
        guard case .success = saveModelSynchronous(model: restaurant) else {
            XCTFail("Failed to save")
            return
        }
        let predicate: QueryPredicate = Restaurant.keys.id == restaurant.id &&
            Restaurant.keys.restaurantName == restaurantName
        guard case .success(let queriedRestaurants) = queryModelSynchronous(modelType: Restaurant.self,
                                                                            predicate: predicate) else {
            XCTFail("Failed to query")
            return
        }
        XCTAssertEqual(queriedRestaurants.count, 1)
        XCTAssertEqual(queriedRestaurants.first!.restaurantName, restaurantName)
        let completed = expectation(description: "operation completed")
        let operation = CascadeDeleteOperation(storageAdapter: storageAdapter,
                                               syncEngine: nil,
                                               modelType: Restaurant.self,
                                               modelSchema: Restaurant.schema,
                                               filter: Restaurant.keys.restaurantName.eq(restaurantName)) { result in
            switch result {
            case .success(let restaurants):
                XCTAssertEqual(restaurants.count, 1)
                XCTAssertEqual(restaurants.first!.restaurantName, restaurantName)
                completed.fulfill()
            case .failure(let error):
                XCTFail("\(error)")
            }
        }
        operation.start()
        wait(for: [completed], timeout: 1)
        guard case .success(let queriedRestaurants) = queryModelSynchronous(modelType: Restaurant.self,
                                                                            predicate: predicate) else {
            XCTFail("Failed to query")
            return
        }
        XCTAssertEqual(queriedRestaurants.count, 0)
    }

    func testWithFilter_NoneMatching() {
        let restaurantName = UUID().uuidString
        let restaurant = Restaurant(restaurantName: restaurantName)
        guard case .success = saveModelSynchronous(model: restaurant) else {
            XCTFail("Failed to save")
            return
        }
        let predicate: QueryPredicate = Restaurant.keys.id == restaurant.id &&
            Restaurant.keys.restaurantName == restaurantName
        guard case .success(let queriedRestaurants) = queryModelSynchronous(modelType: Restaurant.self,
                                                                            predicate: predicate) else {
            XCTFail("Failed to query")
            return
        }
        XCTAssertEqual(queriedRestaurants.count, 1)
        XCTAssertEqual(queriedRestaurants.first!.restaurantName, restaurantName)
        let completed = expectation(description: "operation completed")
        let operation = CascadeDeleteOperation(storageAdapter: storageAdapter,
                                               syncEngine: nil,
                                               modelType: Restaurant.self,
                                               modelSchema: Restaurant.schema,
                                               filter: Restaurant.keys.restaurantName.ne(restaurantName)) { result in
            switch result {
            case .success(let restaurants):
                XCTAssertEqual(restaurants.count, 0)
                completed.fulfill()
            case .failure(let error):
                XCTFail("\(error)")
            }
        }
        operation.start()
        wait(for: [completed], timeout: 1)
        guard case .success(let queriedRestaurants) = queryModelSynchronous(modelType: Restaurant.self,
                                                                            predicate: predicate) else {
            XCTFail("Failed to query")
            return
        }
        XCTAssertEqual(queriedRestaurants.count, 1)
        XCTAssertEqual(queriedRestaurants[0].restaurantName, restaurantName)
    }

    // MARK: - Query and delete (With Sync)

    func testWithId_WithSync() {
        let restaurant = Restaurant(restaurantName: "restaurant1")
        guard case .success = saveModelSynchronous(model: restaurant) else {
            XCTFail("Failed to save")
            return
        }
        let predicate: QueryPredicate = Restaurant.keys.id == restaurant.id
        guard case .success(let queriedRestaurants) = queryModelSynchronous(modelType: Restaurant.self,
                                                                            predicate: predicate) else {
            XCTFail("Failed to query")
            return
        }
        XCTAssertEqual(queriedRestaurants.count, 1)

        let receivedMutationEvent = expectation(description: "Mutation Events submitted to sync engine")
        receivedMutationEvent.expectedFulfillmentCount = 1
        let expectedFailures = expectation(description: "Simulated failure on mutation event submitted to sync engine")
        expectedFailures.isInverted = true
        let expectedSuccess = expectation(description: "Simulated success on mutation event submitted to sync engine")
        expectedSuccess.expectedFulfillmentCount = 1

        syncEngine.setCallbackOnSubmit(callback: { _ in
            receivedMutationEvent.fulfill()
        })

        syncEngine.setReturnOnSubmit { submittedMutationEvent in
            if submittedMutationEvent.modelId == restaurant.id {
                expectedSuccess.fulfill()
                return Future<MutationEvent, DataStoreError> { promise in
                    promise(.success(submittedMutationEvent))
                }
            }

            expectedFailures.fulfill()
            return Future<MutationEvent, DataStoreError> { promise in
                promise(.failure(.internalOperation("mockError", "", nil)))
            }
        }

        let completed = expectation(description: "operation completed")
        let identifier = DefaultModelIdentifier<Restaurant>.makeDefault(id: restaurant.id)
        let operation = CascadeDeleteOperation(storageAdapter: storageAdapter,
                                               syncEngine: syncEngine,
                                               modelType: Restaurant.self,
                                               modelSchema: Restaurant.schema,
                                               withIdentifier: identifier) { result in
            switch result {
            case .success(let restaurant):
                XCTAssertNotNil(restaurant)
                completed.fulfill()
            case .failure(let error):
                XCTFail("\(error)")
            }
        }
        operation.start()
        wait(for: [completed, receivedMutationEvent, expectedFailures, expectedSuccess], timeout: 1)
        guard case .success(let queriedRestaurants) = queryModelSynchronous(modelType: Restaurant.self,
                                                                            predicate: predicate) else {
            XCTFail("Failed to query")
            return
        }
        XCTAssertEqual(queriedRestaurants.count, 0)
    }

    func testWithIdentifier_WithSync() {
        let modelId = "model-id"
        let modelDob = Temporal.DateTime.now()
        let model = ModelCompositePk(id: modelId, dob: modelDob, name: "name")

        guard case .success = saveModelSynchronous(model: model) else {
            XCTFail("Failed to save")
            return
        }
        let predicate: QueryPredicate = ModelCompositePk.keys.id == modelId
            && ModelCompositePk.keys.dob == modelDob
        guard case .success(let queriedModels) = queryModelSynchronous(modelType: ModelCompositePk.self,
                                                                            predicate: predicate) else {
            XCTFail("Failed to query")
            return
        }
        XCTAssertEqual(queriedModels.count, 1)

        let receivedMutationEvent = expectation(description: "Mutation Events submitted to sync engine")
        receivedMutationEvent.expectedFulfillmentCount = 1
        let expectedFailures = expectation(description: "Simulated failure on mutation event submitted to sync engine")
        expectedFailures.isInverted = true
        let expectedSuccess = expectation(description: "Simulated success on mutation event submitted to sync engine")
        expectedSuccess.expectedFulfillmentCount = 1

        syncEngine.setCallbackOnSubmit(callback: { _ in
            receivedMutationEvent.fulfill()
        })

        syncEngine.setReturnOnSubmit { submittedMutationEvent in
            if submittedMutationEvent.modelId == model.identifier {
                expectedSuccess.fulfill()
                return Future<MutationEvent, DataStoreError> { promise in
                    promise(.success(submittedMutationEvent))
                }
            }

            expectedFailures.fulfill()
            return Future<MutationEvent, DataStoreError> { promise in
                promise(.failure(.internalOperation("mockError", "", nil)))
            }
        }

        let completed = expectation(description: "operation completed")
        let identifier = ModelCompositePk.Identifier.identifier(id: modelId, dob: modelDob)
        let operation = CascadeDeleteOperation(storageAdapter: storageAdapter,
                                               syncEngine: syncEngine,
                                               modelType: ModelCompositePk.self,
                                               modelSchema: ModelCompositePk.schema,
                                               withIdentifier: identifier) { result in
            switch result {
            case .success(let restaurant):
                XCTAssertNotNil(restaurant)
                completed.fulfill()
            case .failure(let error):
                XCTFail("\(error)")
            }
        }
        operation.start()
        wait(for: [completed, receivedMutationEvent, expectedFailures, expectedSuccess], timeout: 1)
        guard case .success(let queriedModels) = queryModelSynchronous(modelType: ModelCompositePk.self,
                                                                            predicate: predicate) else {
            XCTFail("Failed to query")
            return
        }
        XCTAssertEqual(queriedModels.count, 0)
    }

    func testWithIdAndCondition_WithSync() {
        let restaurantName = UUID().uuidString
        let restaurant = Restaurant(restaurantName: restaurantName)
        guard case .success = saveModelSynchronous(model: restaurant) else {
            XCTFail("Failed to save")
            return
        }
        let predicate: QueryPredicate = Restaurant.keys.id == restaurant.id &&
            Restaurant.keys.restaurantName == restaurantName
        guard case .success(let queriedRestaurants) = queryModelSynchronous(modelType: Restaurant.self,
                                                                            predicate: predicate) else {
            XCTFail("Failed to query")
            return
        }
        XCTAssertEqual(queriedRestaurants.count, 1)
        XCTAssertEqual(queriedRestaurants.first!.restaurantName, restaurantName)

        let receivedMutationEvent = expectation(description: "Mutation Events submitted to sync engine")
        receivedMutationEvent.expectedFulfillmentCount = 1
        let expectedFailures = expectation(description: "Simulated failure on mutation event submitted to sync engine")
        expectedFailures.isInverted = true
        let expectedSuccess = expectation(description: "Simulated success on mutation event submitted to sync engine")
        expectedSuccess.expectedFulfillmentCount = 1

        syncEngine.setCallbackOnSubmit(callback: { _ in
            receivedMutationEvent.fulfill()
        })

        syncEngine.setReturnOnSubmit { submittedMutationEvent in
            if submittedMutationEvent.modelId == restaurant.id {
                expectedSuccess.fulfill()
                return Future<MutationEvent, DataStoreError> { promise in
                    promise(.success(submittedMutationEvent))
                }
            }

            expectedFailures.fulfill()
            return Future<MutationEvent, DataStoreError> { promise in
                promise(.failure(.internalOperation("mockError", "", nil)))
            }
        }

        let completed = expectation(description: "operation completed")
        let identifier = DefaultModelIdentifier<Restaurant>.makeDefault(id: restaurant.id)
        let operation = CascadeDeleteOperation(storageAdapter: storageAdapter,
                                               syncEngine: syncEngine,
                                               modelType: Restaurant.self,
                                               modelSchema: Restaurant.schema,
                                               withIdentifier: identifier,
                                               condition: Restaurant.keys.restaurantName.eq(restaurantName)) { result in
            switch result {
            case .success(let restaurant):
                XCTAssertNotNil(restaurant)
                completed.fulfill()
            case .failure(let error):
                XCTFail("\(error)")
            }
        }
        operation.start()
        wait(for: [completed, receivedMutationEvent, expectedFailures, expectedSuccess], timeout: 1)
        guard case .success(let queriedRestaurants) = queryModelSynchronous(modelType: Restaurant.self,
                                                                            predicate: predicate) else {
            XCTFail("Failed to query")
            return
        }
        XCTAssertEqual(queriedRestaurants.count, 0)
    }

    func testWithFilter_WithSync() {
        let restaurantName = UUID().uuidString
        let restaurant = Restaurant(restaurantName: restaurantName)
        guard case .success = saveModelSynchronous(model: restaurant) else {
            XCTFail("Failed to save")
            return
        }
        let predicate: QueryPredicate = Restaurant.keys.id == restaurant.id &&
            Restaurant.keys.restaurantName == restaurantName
        guard case .success(let queriedRestaurants) = queryModelSynchronous(modelType: Restaurant.self,
                                                                            predicate: predicate) else {
            XCTFail("Failed to query")
            return
        }
        XCTAssertEqual(queriedRestaurants.count, 1)
        XCTAssertEqual(queriedRestaurants.first!.restaurantName, restaurantName)
        let receivedMutationEvent = expectation(description: "Mutation Events submitted to sync engine")
        receivedMutationEvent.expectedFulfillmentCount = 1
        let expectedFailures = expectation(description: "Simulated failure on mutation event submitted to sync engine")
        expectedFailures.isInverted = true
        let expectedSuccess = expectation(description: "Simulated success on mutation event submitted to sync engine")
        expectedSuccess.expectedFulfillmentCount = 1

        syncEngine.setCallbackOnSubmit(callback: { _ in
            receivedMutationEvent.fulfill()
        })

        syncEngine.setReturnOnSubmit { submittedMutationEvent in
            if submittedMutationEvent.modelId == restaurant.id {
                expectedSuccess.fulfill()
                return Future<MutationEvent, DataStoreError> { promise in
                    promise(.success(submittedMutationEvent))
                }
            }

            expectedFailures.fulfill()
            return Future<MutationEvent, DataStoreError> { promise in
                promise(.failure(.internalOperation("mockError", "", nil)))
            }
        }

        let completed = expectation(description: "operation completed")
        let operation = CascadeDeleteOperation(storageAdapter: storageAdapter,
                                               syncEngine: syncEngine,
                                               modelType: Restaurant.self,
                                               modelSchema: Restaurant.schema,
                                               filter: Restaurant.keys.restaurantName.eq(restaurantName)) { result in
            switch result {
            case .success(let restaurants):
                XCTAssertEqual(restaurants.count, 1)
                XCTAssertEqual(restaurants.first!.restaurantName, restaurantName)
                completed.fulfill()
            case .failure(let error):
                XCTFail("\(error)")
            }
        }
        operation.start()
        wait(for: [completed, receivedMutationEvent, expectedFailures, expectedSuccess], timeout: 1)
        guard case .success(let queriedRestaurants) = queryModelSynchronous(modelType: Restaurant.self,
                                                                            predicate: predicate) else {
            XCTFail("Failed to query")
            return
        }
        XCTAssertEqual(queriedRestaurants.count, 0)
    }

    // MARK: - Internal testing

    func testSingle() {
        let restaurant = Restaurant(restaurantName: "restaurant1")
        guard case .success = saveModelSynchronous(model: restaurant) else {
            XCTFail("Failed to save")
            return
        }
        let identifier = DefaultModelIdentifier<Restaurant>.makeDefault(id: restaurant.id)
        let operation = CascadeDeleteOperation(storageAdapter: storageAdapter,
                                               syncEngine: syncEngine,
                                               modelType: Restaurant.self,
                                               modelSchema: Restaurant.schema,
                                               withIdentifier: identifier) { _ in }

        let result = operation.queryAndDeleteTransaction()
        switch result {
        case .success(let queryAndDeleteResult):
            XCTAssertEqual(queryAndDeleteResult.deletedModels.count, 1)
            XCTAssertEqual(queryAndDeleteResult.associatedModels.count, 0)
        case .failure(let error):
            XCTFail("\(error)")
        }

        let receivedMutationEvent = expectation(description: "Mutation Events submitted to sync engine")
        receivedMutationEvent.expectedFulfillmentCount = 1
        let expectedFailures = expectation(description: "Simulated failure on mutation event submitted to sync engine")
        expectedFailures.isInverted = true
        let expectedSuccess = expectation(description: "Simulated success on mutation event submitted to sync engine")
        expectedSuccess.expectedFulfillmentCount = 1

        syncEngine.setCallbackOnSubmit(callback: { _ in
            receivedMutationEvent.fulfill()
        })

        syncEngine.setReturnOnSubmit { submittedMutationEvent in
            if submittedMutationEvent.modelId == restaurant.id {
                expectedSuccess.fulfill()
                return Future<MutationEvent, DataStoreError> { promise in
                    promise(.success(submittedMutationEvent))
                }
            }

            expectedFailures.fulfill()
            return Future<MutationEvent, DataStoreError> { promise in
                promise(.failure(.internalOperation("mockError", "", nil)))
            }
        }

        operation.syncIfNeededAndFinish(result)
        wait(for: [receivedMutationEvent, expectedFailures, expectedSuccess], timeout: 1)
    }

    func testDeleteWithAssociatedModels() {
        let restaurant = Restaurant(restaurantName: "restaurant1")
        let lunchStandardMenu = Menu(name: "Standard", menuType: .lunch, restaurant: restaurant)
        let oysters = Dish(dishName: "Fried oysters", menu: lunchStandardMenu)

        guard case .success = saveModelSynchronous(model: restaurant),
            case .success = saveModelSynchronous(model: lunchStandardMenu),
            case .success = saveModelSynchronous(model: oysters) else {
                XCTFail("Failed to save hierarchy")
                return
        }
        let completed = expectation(description: "operation completed")
        let identifier = DefaultModelIdentifier<Restaurant>.makeDefault(id: restaurant.id)
        let operation = CascadeDeleteOperation(storageAdapter: storageAdapter,
                                               syncEngine: syncEngine,
                                               modelType: Restaurant.self,
                                               modelSchema: Restaurant.schema,
                                               withIdentifier: identifier) { result in
            switch result {
            case .success:
                completed.fulfill()
            case .failure(let error):
                XCTFail("\(error)")
            }
        }

        let result = operation.queryAndDeleteTransaction()
        switch result {
        case .success(let queryAndDeleteResult):
            XCTAssertEqual(queryAndDeleteResult.deletedModels.count, 1)
            XCTAssertEqual(queryAndDeleteResult.associatedModels.count, 2)
            // The associated models are retrieved in order (Restaurant to Menu to Dish)
            XCTAssertEqual(queryAndDeleteResult.associatedModels[0].0, Menu.modelName)
            XCTAssertEqual(queryAndDeleteResult.associatedModels[1].0, Dish.modelName)
        case .failure(let error):
            XCTFail("\(error)")
        }

        let receivedMutationEvent = expectation(description: "Mutation Events submitted to sync engine")
        receivedMutationEvent.expectedFulfillmentCount = 3
        let expectedFailures = expectation(description: "Simulated failure on mutation event submitted to sync engine")
        expectedFailures.isInverted = true
        let expectedSuccess = expectation(description: "Simulated success on mutation event submitted to sync engine")
        expectedSuccess.expectedFulfillmentCount = 3

        var submittedEvents = [MutationEvent]()
        syncEngine.setCallbackOnSubmit(callback: { mutationEvent in
            submittedEvents.append(mutationEvent)
            receivedMutationEvent.fulfill()
        })

        syncEngine.setReturnOnSubmit { submittedMutationEvent in
            if submittedMutationEvent.modelId == restaurant.id ||
                submittedMutationEvent.modelId == lunchStandardMenu.id ||
                submittedMutationEvent.modelId == oysters.id {
                expectedSuccess.fulfill()
                return Future<MutationEvent, DataStoreError> { promise in
                    promise(.success(submittedMutationEvent))
                }
            }

            expectedFailures.fulfill()
            return Future<MutationEvent, DataStoreError> { promise in
                promise(.failure(.internalOperation("mockError", "", nil)))
            }
        }

        operation.syncIfNeededAndFinish(result)
        wait(for: [completed, receivedMutationEvent, expectedFailures, expectedSuccess], timeout: 1)
        XCTAssertEqual(submittedEvents.count, 3)
        // The delete mutations should be synced in reverse order (children to parent)
        XCTAssertEqual(submittedEvents[0].modelName, Dish.modelName)
        XCTAssertEqual(submittedEvents[1].modelName, Menu.modelName)
        XCTAssertEqual(submittedEvents[2].modelName, Restaurant.modelName)
    }

    func testDeleteWithAssociatedModelsAndCompositePK() {
        let post = PostWithCompositeKey(id: "post-id", title: "title")
        let comment = CommentWithCompositeKey(id: "comment-id", content: "comment-content", post: post)

        if case .failure(let error) = saveModelSynchronous(model: post) {
            XCTFail("Failed to save post with error \(error)")
        }

        if case .failure(let error) = saveModelSynchronous(model: comment) {
            XCTFail("Failed to save comment with error \(error)")
        }

        let completed = expectation(description: "operation completed")
        let identifier = PostWithCompositeKey.Identifier.identifier(id: post.id, title: post.title)
        let operation = CascadeDeleteOperation(storageAdapter: storageAdapter,
                                               syncEngine: syncEngine,
                                               modelType: PostWithCompositeKey.self,
                                               modelSchema: PostWithCompositeKey.schema,
                                               withIdentifier: identifier) { result in
            switch result {
            case .success:
                completed.fulfill()
            case .failure(let error):
                XCTFail("\(error)")
            }
        }

        let result = operation.queryAndDeleteTransaction()
        switch result {
        case .success(let queryAndDeleteResult):
            XCTAssertEqual(queryAndDeleteResult.deletedModels.count, 1)
            XCTAssertEqual(queryAndDeleteResult.associatedModels.count, 1)
            // The associated models are retrieved in order (Restaurant to Menu to Dish)
            XCTAssertEqual(queryAndDeleteResult.associatedModels[0].0, CommentWithCompositeKey.modelName)
        case .failure(let error):
            XCTFail("\(error)")
        }

        let receivedMutationEvent = expectation(description: "Mutation Events submitted to sync engine")
        receivedMutationEvent.expectedFulfillmentCount = 2
        let expectedFailures = expectation(description: "Simulated failure on mutation event submitted to sync engine")
        expectedFailures.isInverted = true
        let expectedSuccess = expectation(description: "Simulated success on mutation event submitted to sync engine")
        expectedSuccess.expectedFulfillmentCount = 2

        var submittedEvents = [MutationEvent]()
        syncEngine.setCallbackOnSubmit(callback: { mutationEvent in
            submittedEvents.append(mutationEvent)
            receivedMutationEvent.fulfill()
        })

        syncEngine.setReturnOnSubmit { submittedMutationEvent in
            if submittedMutationEvent.modelId == post.identifier ||
                submittedMutationEvent.modelId == comment.identifier {
                expectedSuccess.fulfill()
                return Future<MutationEvent, DataStoreError> { promise in
                    promise(.success(submittedMutationEvent))
                }
            }

            expectedFailures.fulfill()
            return Future<MutationEvent, DataStoreError> { promise in
                promise(.failure(.internalOperation("mockError", "", nil)))
            }
        }

        operation.syncIfNeededAndFinish(result)
        wait(for: [completed, receivedMutationEvent, expectedFailures, expectedSuccess], timeout: 1)
        XCTAssertEqual(submittedEvents.count, 2)
        // The delete mutations should be synced in reverse order (children to parent)
        XCTAssertEqual(submittedEvents[0].modelName, CommentWithCompositeKey.modelName)
        XCTAssertEqual(submittedEvents[1].modelName, PostWithCompositeKey.modelName)
    }

    func testDeleteWithAssociatedModels_SingleFailure() {
        let restaurant = Restaurant(restaurantName: "restaurant1")
        let lunchStandardMenu = Menu(name: "Standard", menuType: .lunch, restaurant: restaurant)
        let oysters = Dish(dishName: "Fried oysters", menu: lunchStandardMenu)

        guard case .success = saveModelSynchronous(model: restaurant),
            case .success = saveModelSynchronous(model: lunchStandardMenu),
            case .success = saveModelSynchronous(model: oysters) else {
                XCTFail("Failed to save hierarchy")
                return
        }
        let completed = expectation(description: "operation completed")
        let identifier = DefaultModelIdentifier<Restaurant>.makeDefault(id: restaurant.id)
        let operation = CascadeDeleteOperation(storageAdapter: storageAdapter,
                                               syncEngine: syncEngine,
                                               modelType: Restaurant.self,
                                               modelSchema: Restaurant.schema,
                                               withIdentifier: identifier) { result in
            switch result {
            case .success:
                XCTFail("Should have failed")
            case .failure:
                completed.fulfill()
            }
        }

        let result = operation.queryAndDeleteTransaction()
        switch result {
        case .success(let queryAndDeleteResult):
            XCTAssertEqual(queryAndDeleteResult.deletedModels.count, 1)
            XCTAssertEqual(queryAndDeleteResult.associatedModels.count, 2)
            // The associated models are retrieved in order (Restaurant to Menu to Dish)
            XCTAssertEqual(queryAndDeleteResult.associatedModels[0].0, Menu.modelName)
            XCTAssertEqual(queryAndDeleteResult.associatedModels[1].0, Dish.modelName)
        case .failure(let error):
            XCTFail("\(error)")
        }

        let receivedMutationEvent = expectation(description: "Mutation Events submitted to sync engine")
        receivedMutationEvent.expectedFulfillmentCount = 3
        let expectedFailures = expectation(description: "Simulated failure on mutation event submitted to sync engine")
        expectedFailures.expectedFulfillmentCount = 1
        let expectedSuccess = expectation(description: "Simulated success on mutation event submitted to sync engine")
        expectedSuccess.expectedFulfillmentCount = 2

        var submittedEvents = [MutationEvent]()
        syncEngine.setCallbackOnSubmit(callback: { mutationEvent in
            submittedEvents.append(mutationEvent)
            receivedMutationEvent.fulfill()
        })

        syncEngine.setReturnOnSubmit { submittedMutationEvent in
            if submittedMutationEvent.modelId == restaurant.id ||
                submittedMutationEvent.modelId == oysters.id {
                expectedSuccess.fulfill()
                return Future<MutationEvent, DataStoreError> { promise in
                    promise(.success(submittedMutationEvent))
                }
            }
            // fail on `submittedMutationEvent.modelId == lunchStandardMenu.id`
            expectedFailures.fulfill()
            return Future<MutationEvent, DataStoreError> { promise in
                promise(.failure(.internalOperation("mockError", "", nil)))
            }
        }

        operation.syncIfNeededAndFinish(result)
        wait(for: [completed, receivedMutationEvent, expectedFailures, expectedSuccess], timeout: 1)
        XCTAssertEqual(submittedEvents.count, 3)
        // The delete mutations should be synced in reverse order (children to parent)
        XCTAssertEqual(submittedEvents[0].modelName, Dish.modelName)
        XCTAssertEqual(submittedEvents[1].modelName, Menu.modelName)
        XCTAssertEqual(submittedEvents[2].modelName, Restaurant.modelName)
    }
}
