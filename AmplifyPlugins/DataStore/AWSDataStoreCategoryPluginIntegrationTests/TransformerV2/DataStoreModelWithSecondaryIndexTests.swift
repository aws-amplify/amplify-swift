//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
import AmplifyPlugins
import AWSMobileClient

@testable import Amplify
@testable import AmplifyTestCommon
@testable import AWSDataStoreCategoryPlugin

/*
 # Secondary index

 type CustomerSecondaryIndexV2 @model {
   id: ID!
   name: String!
   phoneNumber: String
   accountRepresentativeID: ID! @index(name: "byRepresentative", queryField: "customerByRepresentative")
 }
 */

class DataStoreModelWithSecondaryIndexTests: SyncEngineIntegrationV2TestBase {

    struct TestModelRegistration: AmplifyModelRegistration {
        func registerModels(registry: ModelRegistry.Type) {
            registry.register(modelType: CustomerSecondaryIndexV2.self)
        }

        let version: String = "1"
    }

    // swiftlint:disable:next cyclomatic_complexity
    func testSaveModelAndSync() throws {
        setUp(withModels: TestModelRegistration())
        try startAmplifyAndWaitForSync()

        guard var customer = saveCustomer(name: "name", accountRepresentativeID: "accountId") else {
            XCTFail("Could not create customer")
            return
        }
        let updatedName = "updatedName"
        let createReceived = expectation(description: "Create notification received")
        let updateReceived = expectation(description: "Update notification received")
        let deleteReceived = expectation(description: "Delete notification received")
        let hubListener = Amplify.Hub.listen(
            to: .dataStore,
            eventName: HubPayload.EventName.DataStore.syncReceived) { payload in
                guard let mutationEvent = payload.data as? MutationEvent
                    else {
                        XCTFail("Can't cast payload as mutation event")
                        return
                }
                guard let customerEvent = try? mutationEvent.decodeModel() as? CustomerSecondaryIndexV2,
                      customerEvent.id == customer.id else {
                    return
                }

                if mutationEvent.mutationType == GraphQLMutationType.create.rawValue {
                    XCTAssertEqual(customerEvent.name, customer.name)
                    XCTAssertEqual(customerEvent.accountRepresentativeID, customer.accountRepresentativeID)
                    XCTAssertEqual(mutationEvent.version, 1)
                    createReceived.fulfill()
                } else if mutationEvent.mutationType == GraphQLMutationType.update.rawValue {
                    XCTAssertEqual(customerEvent.name, updatedName)
                    XCTAssertEqual(mutationEvent.version, 2)
                    updateReceived.fulfill()
                } else if mutationEvent.mutationType == GraphQLMutationType.delete.rawValue {
                    XCTAssertEqual(mutationEvent.version, 3)
                    deleteReceived.fulfill()
                }
        }
        guard try HubListenerTestUtilities.waitForListener(with: hubListener, timeout: 5.0) else {
            XCTFail("Listener not registered for hub")
            return
        }
        let getCustomerCompleted = expectation(description: "get customer complete")
        Amplify.DataStore.query(CustomerSecondaryIndexV2.self, byId: customer.id) { result in
            switch result {
            case .success(let queriedCustomerOptional):
                guard let queriedCustomer = queriedCustomerOptional else {
                    XCTFail("Could not get customer")
                    return
                }
                XCTAssertEqual(queriedCustomer.id, customer.id)
                getCustomerCompleted.fulfill()
            case .failure(let response): XCTFail("Failed with: \(response)")
            }
        }

        wait(for: [getCustomerCompleted, createReceived], timeout: TestCommonConstants.networkTimeout)

        customer.name = updatedName
        let updateCompleted = expectation(description: "update completed")
        Amplify.DataStore.save(customer) { event in
            switch event {
            case .success(let customer):
                XCTAssertEqual(customer.name, updatedName)
                updateCompleted.fulfill()
            case .failure(let error):
                XCTFail("Failed \(error)")
            }
        }
        wait(for: [updateCompleted, updateReceived], timeout: TestCommonConstants.networkTimeout)

        let deleteCompleted = expectation(description: "delete completed")
        Amplify.DataStore.delete(CustomerSecondaryIndexV2.self, withId: customer.id) { event in
            switch event {
            case .success:
                deleteCompleted.fulfill()
            case .failure(let error):
                XCTFail("Failed \(error)")
            }
        }
        wait(for: [deleteCompleted, deleteReceived], timeout: TestCommonConstants.networkTimeout)
    }

    func saveCustomer(name: String, accountRepresentativeID: String) -> CustomerSecondaryIndexV2? {
        let customer = CustomerSecondaryIndexV2(name: name, accountRepresentativeID: accountRepresentativeID)
        var result: CustomerSecondaryIndexV2?
        let completeInvoked = expectation(description: "request completed")
        Amplify.DataStore.save(customer) { event in
            switch event {
            case .success(let data):
                result = data
                completeInvoked.fulfill()
            case .failure(let error):
                XCTFail("Failed \(error)")
            }
        }
        wait(for: [completeInvoked], timeout: TestCommonConstants.networkTimeout)
        return result
    }
}
