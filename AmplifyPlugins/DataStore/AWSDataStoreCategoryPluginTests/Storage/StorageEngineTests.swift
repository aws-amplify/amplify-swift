//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import SQLite
import XCTest

@testable import Amplify
@testable import AmplifyTestCommon
@testable import AWSDataStoreCategoryPlugin

class StorageEngineTests: XCTestCase {

    let defaultTimeout = 0.3
    var connection: Connection!
    var storageEngine: StorageEngine!
    var storageAdapter: SQLiteStorageEngineAdapter!
    var syncEngine: MockRemoteSyncEngine!

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
            do {
                try storageEngine.setUp(modelSchemas: [Restaurant.schema])
                try storageEngine.setUp(modelSchemas: [Menu.schema])
                try storageEngine.setUp(modelSchemas: [Dish.schema])

            } catch {
                XCTFail("Failed to setup storage engine")
            }
        } catch {
            XCTFail(String(describing: error))
            return
        }
    }

    func testDeleteParentEmitsMutationEventsForParentAndChild() {
        let dreamRestaurant = Restaurant(restaurantName: "Dream Cafe")
        let lunchSpecialMenu = Menu(name: "Specials", menuType: .lunch, restaurant: dreamRestaurant)
        let lunchStandardMenu = Menu(name: "Standard", menuType: .lunch, restaurant: dreamRestaurant)
        let oysters = Dish(dishName: "Fried oysters", menu: lunchSpecialMenu)
        let katsuCurry = Dish(dishName: "Katsu Curry", menu: lunchStandardMenu)
        let uniPasta = Dish(dishName: "Uni Pasta", menu: lunchStandardMenu)

        let smoneysRestaurant = Restaurant(restaurantName: "Smoney's")
        let smoneysMenu = Menu(name: "official menu", menuType: .breakfast, restaurant: smoneysRestaurant)
        let eggsAndSausage = Dish(dishName: "Eggs and Sausage", menu: smoneysMenu)

        let mkDonaldsRestaurant = Restaurant(restaurantName: "MkDonald's")
        let mkDonaldsMenu = Menu(name: "All day", menuType: .lunch, restaurant: mkDonaldsRestaurant)
        let szechuanSauce = Dish(dishName: "10-piece MkNugget and a bunch of the Szechuan Sauce", menu: mkDonaldsMenu)

        guard case .success(let savedDreamRestaurant) = saveModelSynchronous(model: dreamRestaurant),
            case .success(let savedLunchSpecialMenu) = saveModelSynchronous(model: lunchSpecialMenu),
            case .success(let savedLunchStandardMenu) = saveModelSynchronous(model: lunchStandardMenu),
            case .success(let savedOysters) = saveModelSynchronous(model: oysters),
            case .success(let savedKatsuCurry) = saveModelSynchronous(model: katsuCurry),
            case .success(let savedUniPasta) = saveModelSynchronous(model: uniPasta),
            case .success = saveModelSynchronous(model: smoneysRestaurant),
            case .success = saveModelSynchronous(model: smoneysMenu),
            case .success = saveModelSynchronous(model: eggsAndSausage),
            case .success = saveModelSynchronous(model: mkDonaldsRestaurant),
            case .success = saveModelSynchronous(model: mkDonaldsMenu),
            case .success = saveModelSynchronous(model: szechuanSauce) else {
                XCTFail("Failed to save hierarchy")
                return
        }

        guard case .success =
            querySingleModelSynchronous(modelType: Restaurant.self, predicate: Restaurant.keys.id == savedDreamRestaurant.id) else {
                XCTFail("Failed to query Restaurant")
                return
        }
        guard case .success =
            queryModelSynchronous(modelType: Menu.self, predicate: Menu.keys.restaurant == savedDreamRestaurant.id) else {
                XCTFail("Failed to query Menu")
                return
        }
        guard case .success(let dishes) =
            queryModelSynchronous(modelType: Dish.self, predicate: Dish.keys.menu == savedLunchStandardMenu.id) else {
                XCTFail("Failed to query Dishes")
                return
        }
        XCTAssertEqual(dishes.count, 2)

        let recievedMutationEvent = expectation(description: "Mutation Events submitted to sync engine")
        recievedMutationEvent.expectedFulfillmentCount = 6
        syncEngine.setCallbackOnSubmit(callback: { _ in
            recievedMutationEvent.fulfill()
        })
        guard case .success = deleteModelSynchronousOrFailOtherwise(modelType: Restaurant.self, withId: savedDreamRestaurant.id) else {
            XCTFail("Failed to delete menu")
            return
        }
        wait(for: [recievedMutationEvent], timeout: defaultTimeout)
    }

    /**
     * Below are synchronous conveinence methods.  Please do not add any calls to XCTFail()
     * in these conveinence methods.  Failures should be handled in the body of the unit test.
     */
    func saveModelSynchronous<M: Model>(model: M) -> DataStoreResult<M> {
        let saveFinished = expectation(description: "Save finished")
        var result: DataStoreResult<M>?

        storageEngine.save(model) { sResult in
            result = sResult
            saveFinished.fulfill()
        }
        wait(for: [saveFinished], timeout: defaultTimeout)
        guard let saveResult = result else {
            return .failure(causedBy: "Save operation timed out")
        }
        return saveResult
    }

    func querySingleModelSynchronous<M: Model>(modelType: M.Type, predicate: QueryPredicate) -> DataStoreResult<M> {
        let result = queryModelSynchronous(modelType: modelType, predicate: predicate)

        switch result {
        case .success(let models):
            if models.isEmpty {
                return .failure(causedBy: "Found no models, of type \(modelType.modelName)")
            } else if models.count > 1 {
                return .failure(causedBy: "Found more than one model of type \(modelType.modelName)")
            } else {
                return .success(models.first!)
            }
        case .failure(let error):
            return .failure(error)
        }
    }

    func queryModelSynchronous<M: Model>(modelType: M.Type, predicate: QueryPredicate) -> DataStoreResult<[M]> {
        let queryFinished = expectation(description: "Query Finished")
        var result: DataStoreResult<[M]>?

        storageEngine.query(modelType, predicate: predicate) { qResult in
            result = qResult
            queryFinished.fulfill()
        }

        wait(for: [queryFinished], timeout: defaultTimeout)
        guard let queryResult = result else {
            return .failure(causedBy: "Query operation timed out")
        }
        return queryResult
    }

    func deleteModelSynchronousOrFailOtherwise<M: Model>(modelType: M.Type, withId id: String) -> DataStoreResult<M> {
        let result = deleteModelSynchronous(modelType: modelType, withId: id)
        switch result {
        case .success(let model):
            if let model = model {
                return .success(model)
            } else {
                return .failure(causedBy: "")
            }
        case .failure(let error):
            return .failure(error)
        }
    }

    func deleteModelSynchronous<M: Model>(modelType: M.Type, withId id: String) -> DataStoreResult<M?> {
        let deleteFinished = expectation(description: "Delete Finished")
        var result: DataStoreResult<M?>?

        storageEngine.delete(modelType, modelSchema: modelType.schema, withId: id, completion: { dResult in
            result = dResult
            deleteFinished.fulfill()
        })

        wait(for: [deleteFinished], timeout: 1)
        guard let deleteResult = result else {
            return .failure(causedBy: "Delete operation timed out")
        }
        return deleteResult
    }
}
