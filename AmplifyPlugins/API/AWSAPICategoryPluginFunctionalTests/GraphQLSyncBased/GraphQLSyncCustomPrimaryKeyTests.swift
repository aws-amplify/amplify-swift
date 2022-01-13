//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
@testable import AWSAPIPlugin
@testable import Amplify
@testable import AmplifyTestCommon
import AWSPluginsCore

class GraphQLSyncCustomPrimaryKeyTests: XCTestCase {

    static let amplifyConfiguration = "testconfiguration/GraphQLSyncBasedTests-amplifyconfiguration"

    override func setUp() {
        Amplify.reset()
        let plugin = AWSAPIPlugin()

        do {
            try Amplify.add(plugin: plugin)

            let amplifyConfig = try TestConfigHelper.retrieveAmplifyConfiguration(
                forResource: GraphQLSyncBasedTests.amplifyConfiguration)
            try Amplify.configure(amplifyConfig)

            ModelRegistry.register(modelType: CustomerOrder.self)

        } catch {
            XCTFail("Error during setup: \(error)")
        }
    }

    override func tearDown() {
        Amplify.reset()
    }

    /// Test for deletion of model with custom primary keys
    ///
    /// - Given: A customer order
    /// - When:
    ///    - The customer order is queried for, updated, deleted and queried for again
    /// - Then:
    ///    - The customer order should be deleted
    ///
    func testDelete() throws {

        /// Create order
        let customerOrder = CustomerOrder(orderId: UUID().uuidString, email: "test@abc.com")
        guard let createMutationSyncResult = createCustomerOrder(customerOrder: customerOrder),
              let createdCustomerOrder = createMutationSyncResult.model.instance as? CustomerOrder else {
            XCTFail("Failed to create customer order")
            return
        }

        /// Query order
        guard let queryMutationSyncResult = queryCustomerOrder(modelName: CustomerOrder.modelName,
                                                          byId: createdCustomerOrder.id,
                                                          orderId: createdCustomerOrder.orderId),
              var queriedCustomerOrder = queryMutationSyncResult.model.instance as? CustomerOrder else {
            XCTFail("Failed to query customer order")
            return
        }

        XCTAssertEqual(customerOrder.id, queriedCustomerOrder.id)

        /// Update order
        queriedCustomerOrder.email = "testnew@abc.com"
        guard let updateMutationSyncResult = updateCustomerOrder(of: queriedCustomerOrder,
                                                                 modelSchema: queriedCustomerOrder.schema,
                                                                 version: queryMutationSyncResult.syncMetadata.version),
              let updatedCustomerOrder = updateMutationSyncResult.model.instance as? CustomerOrder else {
            XCTFail("Failed to update customer order")
            return
        }

        XCTAssertEqual(customerOrder.id, updatedCustomerOrder.id)

        /// Delete order
        guard let deleteMutationSyncResult = deleteCustomerOrder(of: updatedCustomerOrder,
                                        modelSchema: updatedCustomerOrder.schema,
                                        version: updateMutationSyncResult.syncMetadata.version),
              let deletedCustomerOrder = deleteMutationSyncResult.model.instance as? CustomerOrder else {
            XCTFail("Failed to update customer order")
            return
        }

        XCTAssertEqual(customerOrder.id, deletedCustomerOrder.id)

        /// Query after delete
        guard let queryAfterDeleteMutationSyncResult = queryCustomerOrder(modelName: CustomerOrder.modelName,
                                                                          byId: deletedCustomerOrder.id,
                                                                          orderId: deletedCustomerOrder.orderId),
              let queryDeletedCustomerOrder = queryAfterDeleteMutationSyncResult.model.instance as? CustomerOrder else {
            XCTFail("Failed to query customer order")
            return
        }

        XCTAssertEqual(queryDeletedCustomerOrder.id, customerOrder.id)
        XCTAssertTrue(queryAfterDeleteMutationSyncResult.syncMetadata.deleted)
    }

    // MARK: - Helpers

    func createCustomerOrder(customerOrder: CustomerOrder) -> MutationSyncResult? {
        var result: MutationSyncResult?
        let completeInvoked = expectation(description: "request completed")

        let request = GraphQLRequest<MutationSyncResult>.createMutation(of: customerOrder)
        _ = Amplify.API.mutate(request: request, listener: { event in
            switch event {
            case .success(let data):
                switch data {
                case .success(let post):
                    result = post
                case .failure(let error):
                    XCTFail("Failed to create post \(error)")
                }
                completeInvoked.fulfill()
            case .failure(let error):
                print(error)
            }
        })
        wait(for: [completeInvoked], timeout: TestCommonConstants.networkTimeout)
        return result
    }

    func queryCustomerOrder(modelName: String,
                            byId id: String,
                            orderId: String) -> MutationSyncResult? {
        var documentBuilder = ModelBasedGraphQLDocumentBuilder(modelName: modelName, operationType: .query)
        documentBuilder.add(decorator: DirectiveNameDecorator(type: .get))
        documentBuilder.add(decorator: ModelIdDecorator(id: id, fields: ["orderId": orderId]))
        documentBuilder.add(decorator: ConflictResolutionDecorator())
        documentBuilder.add(decorator: AuthRuleDecorator(.query))
        let document = documentBuilder.build()

        let queryRequest = GraphQLRequest<MutationSyncResult?>(document: document.stringValue,
                                                               variables: document.variables,
                                                               responseType: MutationSyncResult?.self,
                                                               decodePath: document.name)
        var querySyncResult: MutationSyncResult?
        let querySuccess = expectation(description: "query successful")
        _ = Amplify.API.query(request: queryRequest) { event in
            switch event {
            case .success(let response):
                switch response {
                case .success(let mutationSync):
                    querySyncResult = mutationSync
                case .failure(let graphQLError):
                    XCTFail("\(graphQLError)")
                }
                querySuccess.fulfill()
            case .failure(let error):
                XCTFail("\(error)")
            }
        }
        wait(for: [querySuccess], timeout: TestCommonConstants.networkTimeout)
        return querySyncResult
    }

    func updateCustomerOrder(of model: Model,
                             modelSchema: ModelSchema,
                             version: Int) -> MutationSyncResult? {
        let updateSuccess = expectation(description: "update successful")
        let updateRequest = GraphQLRequest<MutationSyncResult>.updateMutation(
            of: model,
            modelSchema: modelSchema,
            version: version)

        var updateSyncResult: MutationSyncResult?
        _ = Amplify.API.mutate(request: updateRequest) { event in
            switch event {
            case .success(let response):
                switch response {
                case .success(let mutationSync):
                    updateSyncResult = mutationSync
                case .failure(let graphQLError):
                    XCTFail("\(graphQLError)")
                }
                updateSuccess.fulfill()
            case .failure(let error):
                XCTFail("\(error)")
            }
        }
        wait(for: [updateSuccess], timeout: TestCommonConstants.networkTimeout)
        return updateSyncResult
    }

    func deleteCustomerOrder(of model: Model,
                             modelSchema: ModelSchema,
                             version: Int) -> MutationSyncResult? {
        let deleteSuccess = expectation(description: "delete successful")
        let deleteRequest = GraphQLRequest<MutationSyncResult>.deleteMutation(
            of: model,
            modelSchema: modelSchema,
            version: version)

        var deleteSyncResult: MutationSyncResult?
        _ = Amplify.API.mutate(request: deleteRequest) { event in
            switch event {
            case .success(let response):
                switch response {
                case .success(let mutationSync):
                    deleteSyncResult = mutationSync
                case .failure(let graphQLError):
                    XCTFail("\(graphQLError)")
                }
                deleteSuccess.fulfill()
            case .failure(let error):
                XCTFail("\(error)")
            }
        }
        wait(for: [deleteSuccess], timeout: TestCommonConstants.networkTimeout)
        return deleteSyncResult
    }
}
