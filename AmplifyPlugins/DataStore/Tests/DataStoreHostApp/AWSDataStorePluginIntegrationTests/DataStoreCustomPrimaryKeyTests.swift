//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest

import AWSPluginsCore

@testable import Amplify
@testable import AWSDataStorePlugin

// swiftlint:disable cyclomatic_complexity
class DataStoreCustomPrimaryKeyTests: SyncEngineIntegrationTestBase {

    struct TestModelRegistration: AmplifyModelRegistration {
        func registerModels(registry: ModelRegistry.Type) {
            registry.register(modelType: CustomerOrder.self)
        }

        let version: String = "1"
    }

    /// - Given: API has been setup with CustomerOrder model registered
    /// - When: A new customer order is
    ///     - saved, updated and queried - should return the saved model
    ///     - deleted
    ///     - queried
    /// - Then: The model should be deleted finally and the sync events should be received in order
    func testDeleteModelWithCustomPrimaryKey() async throws {
        await setUp(withModels: TestModelRegistration())
        try await startAmplifyAndWaitForSync()
        let customerOrder = CustomerOrder(orderId: UUID().uuidString, email: "test@abc.com")

        let createReceived = expectation(description: "Create notification received")
        var updatedCustomerOrder = customerOrder
        updatedCustomerOrder.email = "testnew@abc.com"
        var hubListener = Amplify.Hub.listen(
            to: .dataStore,
            eventName: HubPayload.EventName.DataStore.syncReceived) { payload in
                guard let mutationEvent = payload.data as? MutationEvent
                    else {
                        XCTFail("Can't cast payload as mutation event")
                        return
                }

                guard let order = try? mutationEvent.decodeModel() as? CustomerOrder,
                      order.id == customerOrder.id else {
                    return
                }

                if mutationEvent.mutationType == GraphQLMutationType.create.rawValue {
                    XCTAssertEqual(order.email, customerOrder.email)
                    XCTAssertEqual(order.orderId, customerOrder.orderId)
                    XCTAssertEqual(mutationEvent.version, 1)
                    createReceived.fulfill()
                    return
                }
        }
        guard try await HubListenerTestUtilities.waitForListener(with: hubListener, timeout: 5.0) else {
            XCTFail("Listener not registered for hub")
            return
        }

        // create customer order
        _ = try await Amplify.DataStore.save(customerOrder)
        await waitForExpectations(timeout: networkTimeout)

        // update customer order
        let updateReceived = expectation(description: "Update notification received")
        hubListener = Amplify.Hub.listen(
            to: .dataStore,
            eventName: HubPayload.EventName.DataStore.syncReceived) { payload in
                guard let mutationEvent = payload.data as? MutationEvent
                    else {
                        XCTFail("Can't cast payload as mutation event")
                        return
                }

                guard let order = try? mutationEvent.decodeModel() as? CustomerOrder,
                      order.id == customerOrder.id else {
                    return
                }

            
                if mutationEvent.mutationType == GraphQLMutationType.update.rawValue {
                    XCTAssertEqual(order.email, updatedCustomerOrder.email)
                    XCTAssertEqual(order.orderId, updatedCustomerOrder.orderId)
                    XCTAssertEqual(mutationEvent.version, 2)
                    updateReceived.fulfill()
                    return
                }

        }
        guard try await HubListenerTestUtilities.waitForListener(with: hubListener, timeout: 5.0) else {
            XCTFail("Listener not registered for hub")
            return
        }
        _ = try await Amplify.DataStore.save(updatedCustomerOrder)
        await waitForExpectations(timeout: networkTimeout)
        
        // query the updated order
        let queriedOrder = try await Amplify.DataStore.query(CustomerOrder.self, byId: updatedCustomerOrder.id)
        guard let order = queriedOrder else {
            XCTFail("Queried model is nil")
            return
        }
        XCTAssertEqual(order.id, updatedCustomerOrder.id)
        XCTAssertEqual(order.orderId, updatedCustomerOrder.orderId)
        XCTAssertEqual(order.email, updatedCustomerOrder.email)
        
        // delete the customer order
        let deleteReceived = expectation(description: "Delete notification received")
        hubListener = Amplify.Hub.listen(
            to: .dataStore,
            eventName: HubPayload.EventName.DataStore.syncReceived) { payload in
                guard let mutationEvent = payload.data as? MutationEvent
                    else {
                        XCTFail("Can't cast payload as mutation event")
                        return
                }

                guard let order = try? mutationEvent.decodeModel() as? CustomerOrder,
                      order.id == customerOrder.id else {
                    return
                }

                if mutationEvent.mutationType == GraphQLMutationType.delete.rawValue {
                    XCTAssertEqual(order.email, updatedCustomerOrder.email)
                    XCTAssertEqual(order.orderId, updatedCustomerOrder.orderId)
                    XCTAssertEqual(mutationEvent.version, 3)
                    deleteReceived.fulfill()
                    return
                }
        }
        guard try await HubListenerTestUtilities.waitForListener(with: hubListener, timeout: 5.0) else {
            XCTFail("Listener not registered for hub")
            return
        }
        _ = try await Amplify.DataStore.delete(CustomerOrder.self, withId: updatedCustomerOrder.id)
        await waitForExpectations(timeout: networkTimeout)
        
        // query the customer order after deletion
        let queriedOrder2 = try await Amplify.DataStore.query(CustomerOrder.self, byId: updatedCustomerOrder.id)
        XCTAssertNil(queriedOrder2)
    }

}
