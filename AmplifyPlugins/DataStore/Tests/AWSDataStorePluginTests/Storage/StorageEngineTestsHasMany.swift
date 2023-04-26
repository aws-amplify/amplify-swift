//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Combine
import Foundation
import SQLite
import XCTest

@testable import Amplify
@testable import AmplifyTestCommon
@testable import AWSDataStorePlugin

class StorageEngineTestsHasMany: StorageEngineTestsBase {

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

    func testDeleteParentEmitsMutationEventsForParentAndChild() async {
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

        guard case .success = await saveModel(model: dreamRestaurant),
            case .success = await saveModel(model: lunchSpecialMenu),
            case .success = await saveModel(model: lunchStandardMenu),
            case .success = await saveModel(model: oysters),
            case .success = await saveModel(model: katsuCurry),
            case .success = await saveModel(model: uniPasta),
            case .success = await saveModel(model: smoneysRestaurant),
            case .success = await saveModel(model: smoneysMenu),
            case .success = await saveModel(model: eggsAndSausage),
            case .success = await saveModel(model: mkDonaldsRestaurant),
            case .success = await saveModel(model: mkDonaldsMenu),
            case .success = await saveModel(model: szechuanSauce) else {
                XCTFail("Failed to save hierarchy")
                return
        }

        guard case .success =
            querySingleModel(modelType: Restaurant.self,
                                        predicate: Restaurant.keys.id == dreamRestaurant.id) else {
                XCTFail("Failed to query Restaurant")
                return
        }
        guard case .success =
            queryModel(modelType: Menu.self, predicate: Menu.keys.restaurant == dreamRestaurant.id) else {
                XCTFail("Failed to query Menu")
                return
        }
        guard case .success(let dishes) =
            queryModel(modelType: Dish.self, predicate: Dish.keys.menu == lunchStandardMenu.id) else {
                XCTFail("Failed to query Dishes")
                return
        }
        XCTAssertEqual(dishes.count, 2)

        let receivedMutationEvent = expectation(description: "Mutation Events submitted to sync engine")
        receivedMutationEvent.expectedFulfillmentCount = 6
        syncEngine.setCallbackOnSubmit { submittedMutationEvent in
            receivedMutationEvent.fulfill()
            return .success(submittedMutationEvent)
        }
        guard case .success = await deleteModelOrFailOtherwise(modelType: Restaurant.self,
                                                                    withId: dreamRestaurant.id) else {
            XCTFail("Failed to delete restaurant")
            return
        }
        await fulfillment(of: [receivedMutationEvent], timeout: defaultTimeout)
    }

    /*
     *  Running on Core i9 2.3ghz (in-memory, theoretical performance)
     *  100    iterations (~200 expressions)  - .8716s
     *  200    iterations (~400 expressions)  - 2.08s
     *  400    iterations (~800 expressions)  - 3.8s
     *  1000   iterations (~2000 expressions) - 12.14s
     *  5000   iterations (~10000 expressions) - 110.62s
     *
     *  A delete can be an expensive operation because when we delete models of "Dish" we need to create
     *  a query expression comprised of a number of equality expressions, in order to figure out what
     *  MutationEvents to send to the backend.

     *  In this use case, one of the query expressions we would need to generate would be something like this:
     *  '''
     *  Give me all of the dishes, which have an (dishMenuId == id1) || (dishmenuId == id2) || .. etc..
     *  '''
     *  The result of this query is used to generate MutationEvent(s) to send to the backend.
     *
     *  Note that because the maximum number of expressions that SQLite supports is 1000, we work around this
     *  by chunking this expression into chunks of 950.  For example, if you have 951 expressions, we will
     *  make two queries: One query with 950 expressions, and one query with 1 expression.
     *
     */
    func testStressDeleteTopLeveleagerLoadHasManyRelationship() async {
        let iterations = 500
        let numberOfMenus = iterations * 2
        let numberOfDishes = iterations * 4

        let restaurant1 = Restaurant(restaurantName: "Cafe1")
        guard case .success = await saveModel(model: restaurant1) else {
            XCTFail("Failed to save restaurant")
            return
        }

        for iteration in 0 ..< iterations {
            let menu1 = Menu(name: "Specials\(iteration)", menuType: .lunch, restaurant: restaurant1)
            let menu2 = Menu(name: "Standard\(iteration)", menuType: .lunch, restaurant: restaurant1)
            let oysters = Dish(dishName: "Fried oysters\(iteration)", menu: menu1)
            let tataki = Dish(dishName: "Tuna tataki\(iteration)", menu: menu1)
            let katsuCurry = Dish(dishName: "Katsu Curry\(iteration)", menu: menu2)
            let katsuDon = Dish(dishName: "Katsu don\(iteration)", menu: menu2)

            guard case .success = await saveModel(model: menu1),
                case .success = await saveModel(model: menu2),
                case .success = await saveModel(model: oysters),
                case .success = await saveModel(model: tataki),
                case .success = await saveModel(model: katsuCurry),
                case .success = await saveModel(model: katsuDon) else {

                    XCTFail("Failed to save hierarchy")
                    return
            }
        }
        // Query individually without lazy loading and verify counts.
        guard case .success(let savedRestaurant) =
            querySingleModel(modelType: Restaurant.self,
                                        predicate: Restaurant.keys.id == restaurant1.id) else {
                                            XCTFail("Failed to query Restaurant")
                                            return
        }
        XCTAssertEqual(savedRestaurant.id, restaurant1.id)
        guard case .success(let menus) =
            queryModel(modelType: Menu.self,
                                  predicate: QueryPredicateConstant.all) else {
                                    XCTFail("Failed to query menus")
                                    return
        }
        XCTAssertEqual(menus.count, numberOfMenus)
        guard case .success(let dishes) =
            queryModel(modelType: Dish.self,
                                  predicate: QueryPredicateConstant.all) else {
                                    XCTFail("Failed to query dishes")
                                    return
        }
        XCTAssertEqual(dishes.count, numberOfDishes)

        // let startTime = CFAbsoluteTimeGetCurrent()
        // Delete Top level of restaurant
        let receivedMutationEvent = expectation(description: "Mutation Events submitted to sync engine")
        receivedMutationEvent.expectedFulfillmentCount = numberOfMenus + numberOfDishes + 1
        syncEngine.setCallbackOnSubmit { submittedMutationEvent in
            receivedMutationEvent.fulfill()
            return .success(submittedMutationEvent)
        }
        guard case .success = await deleteModelOrFailOtherwise(modelType: Restaurant.self,
                                                                    withId: restaurant1.id,
                                                                    timeout: 100) else {
                                                                        XCTFail("Failed to delete restaurant")
                                                                        return
        }
        wait(for: [receivedMutationEvent], timeout: 100)
        // let timeElapsed = CFAbsoluteTimeGetCurrent() - startTime
        // print("Time elapsed time to delete: \(timeElapsed) s.")
    }

    func testErrorOnSingleSubmissionToSyncEngine() async {
         let restaurant1 = Restaurant(restaurantName: "restaurant1")
         let lunchStandardMenu = Menu(name: "Standard", menuType: .lunch, restaurant: restaurant1)
         let oysters = Dish(dishName: "Fried oysters", menu: lunchStandardMenu)

         guard case .success = await saveModel(model: restaurant1),
             case .success = await saveModel(model: lunchStandardMenu),
             case .success = await saveModel(model: oysters) else {
                 XCTFail("Failed to save hierarchy")
                 return
         }

        let receivedMutationEvent = expectation(description: "Mutation Events submitted to sync engine")
        receivedMutationEvent.expectedFulfillmentCount = 3
        let expectedFailures = expectation(description: "Simulated failure on mutation event submitted to sync engine")
        expectedFailures.expectedFulfillmentCount = 2
        let expectedSuccess = expectation(description: "Simulated success on mutation event submitted to sync engine")
        expectedSuccess.expectedFulfillmentCount = 1

        syncEngine.setCallbackOnSubmit { submittedMutationEvent in
            receivedMutationEvent.fulfill()
            if submittedMutationEvent.modelId == lunchStandardMenu.id ||
                submittedMutationEvent.modelId == oysters.id {
                expectedFailures.fulfill()
                return .failure(.internalOperation("mockError", "", nil))
            } else {
                expectedSuccess.fulfill()
                return .success(submittedMutationEvent)
            }
        }

        guard case .failure(let error) = await deleteModelOrFailOtherwise(modelType: Restaurant.self,
                                                                               withId: restaurant1.id) else {
            XCTFail("Deleting should have failed due to our mock")
            return
        }
        await fulfillment(of: [receivedMutationEvent, expectedFailures, expectedSuccess], timeout: defaultTimeout)
        XCTAssertEqual(error.errorDescription, "mockError")
    }
}
