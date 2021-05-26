//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
@testable import AWSAPICategoryPlugin
@testable import Amplify
@testable import AmplifyTestCommon
@testable import AWSAPICategoryPluginTestCommon
import AWSPluginsCore

// swiftlint:disable cyclomatic_complexity
class GraphQLSyncCustomPrimaryKeyTests: XCTestCase {

    static let amplifyConfiguration = "GraphQLSyncBasedTests-amplifyconfiguration"

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
        guard let mutationSyncResult = createCustomerOrder(customerOrder: customerOrder),
              let _ = mutationSyncResult.model.instance as? CustomerOrder else {
            XCTFail("Failed to create customer order")
            return
        }

        /// Query order
        let querySuccess = expectation(description: "query successful")
        let queryRequest = queryCustomerOrder(modelName: CustomerOrder.modelName,
                                         byId: customerOrder.id,
                                         orderId: customerOrder.orderId)
        Amplify.API.query(request: queryRequest) { result in
            switch result {
            case .success(let response):
                switch response {
                case .success(let mutationSync):
                    guard let queriedCustomerOrder = mutationSync?.model.instance as? CustomerOrder else {
                        XCTFail("Failed to retrieve customer order")
                        return
                    }
                    XCTAssertEqual(queriedCustomerOrder.id, customerOrder.id)
                    querySuccess.fulfill()
                case .failure(let graphQLError):
                    XCTFail("\(graphQLError)")
                }
            case .failure(let error):
                XCTFail("\(error)")
            }
        }
        wait(for: [querySuccess], timeout: TestCommonConstants.networkTimeout)

        /// Update order
        let updatedCustomerOrder = CustomerOrder(id: mutationSyncResult.model["id"] as? String ?? "",
                                                 orderId: mutationSyncResult.model["orderId"] as? String ?? "",
                                                 email: "testnew@abc.com")

        let updateSuccess = expectation(description: "update successful")
        let updateRequest = GraphQLRequest<MutationSyncResult>.updateMutation(
            of: updatedCustomerOrder,
            modelSchema: updatedCustomerOrder.schema,
            version: mutationSyncResult.syncMetadata.version)
        var updateSyncResult: MutationSyncResult?

        Amplify.API.mutate(request: updateRequest) { result in
            switch result {
            case .success(let response):
                switch response {
                case .success(let mutationSync):
                    guard let queriedCustomerOrder = mutationSync.model.instance as? CustomerOrder else {
                        XCTFail("Failed to retrieve customer order")
                        return
                    }
                    updateSyncResult = mutationSync
                    XCTAssertEqual(queriedCustomerOrder.id, customerOrder.id)
                    updateSuccess.fulfill()
                case .failure(let graphQLError):
                    XCTFail("\(graphQLError)")
                }
            case .failure(let error):
                XCTFail("\(error)")
            }
        }
        wait(for: [updateSuccess], timeout: TestCommonConstants.networkTimeout)

        guard let updatedSyncResult = updateSyncResult else {
            XCTFail("failed to sync update")
            return
        }

        /// Delete order
        let deleteSuccess = expectation(description: "delete successful")
        let deleteRequest = GraphQLRequest<MutationSyncResult>.deleteMutation(
            of: updatedCustomerOrder,
            modelSchema: updatedCustomerOrder.schema,
            version: updatedSyncResult.syncMetadata.version)
        Amplify.API.mutate(request: deleteRequest) { result in
            switch result {
            case .success(let response):
                switch response {
                case .success(let mutationSync):
                    guard let queriedCustomerOrder = mutationSync.model.instance as? CustomerOrder else {
                        XCTFail("Failed to retrieve customer order")
                        return
                    }
                    XCTAssertEqual(queriedCustomerOrder.id, updatedCustomerOrder.id)
                    deleteSuccess.fulfill()
                case .failure(let graphQLError):
                    XCTFail("\(graphQLError)")
                }
            case .failure(let error):
                XCTFail("\(error)")
            }
        }
        wait(for: [deleteSuccess], timeout: TestCommonConstants.networkTimeout)

        /// Query after delete
        let queryDeleted = expectation(description: "query successful")
        Amplify.API.query(request: queryCustomerOrder(modelName: CustomerOrder.modelName,
                                                      byId: updatedCustomerOrder.id,
                                                      orderId: updatedCustomerOrder.orderId)) { result in
            switch result {
            case .success(let response):
                switch response {
                case .success(let mutationSync):
                    guard let queriedCustomerOrder = mutationSync?.model.instance as? CustomerOrder else {
                        XCTFail("Failed to retrieve customer order")
                        return
                    }
                    XCTAssertEqual(queriedCustomerOrder.id, customerOrder.id)
                    if let isDeleted = mutationSync?.syncMetadata.deleted {
                        XCTAssertTrue(isDeleted)
                    } else {
                        XCTFail("Should be deleted")
                    }
                    queryDeleted.fulfill()
                case .failure(let graphQLError):
                    XCTFail("\(graphQLError)")
                }
            case .failure(let error):
                XCTFail("\(error)")
            }
        }
        wait(for: [queryDeleted], timeout: TestCommonConstants.networkTimeout)
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

    public func queryCustomerOrder(modelName: String,
                                   byId id: String,
                                   orderId: String) -> GraphQLRequest<MutationSyncResult?> {
        var documentBuilder = ModelBasedGraphQLDocumentBuilder(modelName: modelName, operationType: .query)
        documentBuilder.add(decorator: DirectiveNameDecorator(type: .get))
        documentBuilder.add(decorator: ModelIdDecorator(id: id, fields: ["orderId": orderId]))
        documentBuilder.add(decorator: ConflictResolutionDecorator())
        documentBuilder.add(decorator: AuthRuleDecorator(.query))
        let document = documentBuilder.build()

        return GraphQLRequest<MutationSyncResult?>(document: document.stringValue,
                                                   variables: document.variables,
                                                   responseType: MutationSyncResult?.self,
                                                   decodePath: document.name)
    }
}
