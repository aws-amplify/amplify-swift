//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
@testable import Amplify
@testable import AmplifyTestCommon
@testable import AWSPluginsCore

class GraphQLRequestSyncCustomPrimaryKeyTests: XCTestCase {

    override func setUp() {
        ModelRegistry.register(modelType: CustomerOrder.self)
    }

    override func tearDown() {
        ModelRegistry.reset()
    }

    func testQueryGraphQLRequest() throws {
        let order = CustomerOrder(orderId: "testOrderId", email: "testEmail@provider.com")
        var documentBuilder = ModelBasedGraphQLDocumentBuilder(modelName: order.modelName,
                                                               operationType: .query)
        documentBuilder.add(decorator: DirectiveNameDecorator(type: .get))
        documentBuilder.add(decorator: ModelIdDecorator(id: order.id, fields: ["orderId": "testOrderId"]))
        documentBuilder.add(decorator: ConflictResolutionDecorator(graphQLType: .query))
        let document = documentBuilder.build()
        let documentStringValue = """
        query GetCustomerOrder {
          getCustomerOrder(id: "\(order.id)", orderId: "\(order.orderId)") {
            orderId
            id
            email
            __typename
            _version
            _deleted
            _lastChangedAt
          }
        }
        """

        XCTAssertEqual(document.stringValue, documentStringValue)

        let request = GraphQLRequest<MutationSyncResult>(document: document.stringValue,
                                                          variables: document.variables,
                                                          responseType: MutationSyncResult.self,
                                                          decodePath: document.name)

        XCTAssertEqual(request.document, document.stringValue)
        XCTAssert(request.responseType == MutationSyncResult.self)
        guard let variables = request.variables else {
            XCTFail("The request doesn't contain variables")
            return
        }

        XCTAssertTrue(variables.isEmpty)
    }

    func testCreateMutationGraphQLRequest() throws {
        let order = CustomerOrder(orderId: "testOrderId", email: "testEmail@provider.com")
        var documentBuilder = ModelBasedGraphQLDocumentBuilder(modelName: order.modelName,
                                                               operationType: .mutation)
        documentBuilder.add(decorator: DirectiveNameDecorator(type: .create))
        documentBuilder.add(decorator: ModelDecorator(model: order, mutationType: .create))
        documentBuilder.add(decorator: ConflictResolutionDecorator(graphQLType: .mutation))
        let document = documentBuilder.build()
        let documentStringValue = """
        mutation CreateCustomerOrder($input: CreateCustomerOrderInput!) {
          createCustomerOrder(input: $input) {
            orderId
            id
            email
            __typename
            _version
            _deleted
            _lastChangedAt
          }
        }
        """
        XCTAssertEqual(document.stringValue, documentStringValue)

        guard let expectedInput = document.variables?["input"] as? [String: Any] else {
            XCTFail("The document variables property doesn't contain a valid input")
            return
        }

        let request = GraphQLRequest<MutationSyncResult>.createMutation(of: order, modelSchema: order.schema)

        XCTAssertEqual(request.document, document.stringValue)
        XCTAssert(request.responseType == MutationSyncResult.self)

        guard let variables = request.variables else {
            XCTFail("The request doesn't contain variables")
            return
        }
        guard let input = variables["input"] as? [String: Any] else {
            XCTFail("The document variables property doesn't contain a valid input")
            return
        }

        XCTAssertEqual(input["id"] as? String, order.id)
        XCTAssertEqual(input["email"] as? String, order.email)
        XCTAssertEqual(input["orderId"] as? String, order.orderId)

        XCTAssertEqual(input["id"] as? String, expectedInput["id"] as? String)
        XCTAssertEqual(input["email"] as? String, expectedInput["email"] as? String)
        XCTAssertEqual(input["orderId"] as? String, expectedInput["orderId"] as? String)
    }

    func testUpdateMutationGraphQLRequest() throws {
        let order = CustomerOrder(orderId: "testOrderId", email: "testEmail@provider.com")
        var documentBuilder = ModelBasedGraphQLDocumentBuilder(modelName: order.modelName,
                                                               operationType: .mutation)
        documentBuilder.add(decorator: DirectiveNameDecorator(type: .update))
        documentBuilder.add(decorator: ModelDecorator(model: order, mutationType: .create))
        documentBuilder.add(decorator: ConflictResolutionDecorator(version: 1, lastSync: nil, graphQLType: .mutation))
        let document = documentBuilder.build()
        let documentStringValue = """
        mutation UpdateCustomerOrder($input: UpdateCustomerOrderInput!) {
          updateCustomerOrder(input: $input) {
            orderId
            id
            email
            __typename
            _version
            _deleted
            _lastChangedAt
          }
        }
        """

        XCTAssertEqual(document.stringValue, documentStringValue)

        guard let expectedInput = document.variables?["input"] as? [String: Any] else {
            XCTFail("The document variables property doesn't contain a valid input")
            return
        }

        let request = GraphQLRequest<MutationSyncResult>.updateMutation(of: order,
                                                                        modelSchema: order.schema,
                                                                        version: 1)

        XCTAssertEqual(request.document, document.stringValue)
        XCTAssert(request.responseType == MutationSyncResult.self)

        guard let variables = request.variables else {
            XCTFail("The request doesn't contain variables")
            return
        }
        guard let input = variables["input"] as? [String: Any] else {
            XCTFail("The document variables property doesn't contain a valid input")
            return
        }

        XCTAssertEqual(input["id"] as? String, order.id)
        XCTAssertEqual(input["email"] as? String, order.email)
        XCTAssertEqual(input["orderId"] as? String, order.orderId)
        XCTAssertEqual(input["_version"] as? Int, 1)

        XCTAssertEqual(input["id"] as? String, expectedInput["id"] as? String)
        XCTAssertEqual(input["email"] as? String, expectedInput["email"] as? String)
        XCTAssertEqual(input["orderId"] as? String, expectedInput["orderId"] as? String)
        XCTAssertEqual(input["_version"] as? Int, expectedInput["_version"] as? Int)
    }

    func testDeleteMutationGraphQLRequest() throws {
        let order = CustomerOrder(orderId: "testOrderId", email: "testEmail@provider.com")
        var documentBuilder = ModelBasedGraphQLDocumentBuilder(modelName: order.modelName,
                                                               operationType: .mutation)
        documentBuilder.add(decorator: DirectiveNameDecorator(type: .delete))
        documentBuilder.add(decorator: ModelIdDecorator(model: order))
        documentBuilder.add(decorator: ConflictResolutionDecorator(version: 1, lastSync: nil, graphQLType: .mutation))
        let document = documentBuilder.build()
        let documentStringValue = """
        mutation DeleteCustomerOrder($input: DeleteCustomerOrderInput!) {
          deleteCustomerOrder(input: $input) {
            orderId
            id
            email
            __typename
            _version
            _deleted
            _lastChangedAt
          }
        }
        """

        XCTAssertEqual(document.stringValue, documentStringValue)

        guard let expectedInput = document.variables?["input"] as? [String: Any] else {
            XCTFail("The document variables property doesn't contain a valid input")
            return
        }

        let request = GraphQLRequest<MutationSyncResult>.deleteMutation(of: order,
                                                                        modelSchema: order.schema,
                                                                        version: 1)

        XCTAssertEqual(request.document, document.stringValue)
        XCTAssert(request.responseType == MutationSyncResult.self)

        guard let variables = request.variables else {
            XCTFail("The request doesn't contain variables")
            return
        }
        guard let input = variables["input"] as? [String: Any] else {
            XCTFail("The document variables property doesn't contain a valid input")
            return
        }

        XCTAssertEqual(input["id"] as? String, order.id)
        XCTAssertEqual(input["orderId"] as? String, order.orderId)
        XCTAssertEqual(input["_version"] as? Int, 1)

        XCTAssertEqual(input["id"] as? String, expectedInput["id"] as? String)
        XCTAssertEqual(input["orderId"] as? String, expectedInput["orderId"] as? String)
        XCTAssertEqual(input["_version"] as? Int, expectedInput["_version"] as? Int)
    }
}
