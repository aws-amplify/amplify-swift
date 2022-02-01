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
        ModelRegistry.register(modelType: CustomerWithDateInPK.self)
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
        documentBuilder.add(decorator: ConflictResolutionDecorator())
        let document = documentBuilder.build()
        let documentStringValue = """
        query GetCustomerOrder($id: ID!, $orderId: String!) {
          getCustomerOrder(id: $id, orderId: $orderId) {
            id
            email
            orderId
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

        XCTAssertEqual(variables["id"] as? String, order.id)
        XCTAssertEqual(variables["orderId"] as? String, order.orderId)
    }

    func testCreateMutationGraphQLRequest() throws {
        let order = CustomerOrder(orderId: "testOrderId", email: "testEmail@provider.com")
        var documentBuilder = ModelBasedGraphQLDocumentBuilder(modelName: order.modelName,
                                                               operationType: .mutation)
        documentBuilder.add(decorator: DirectiveNameDecorator(type: .create))
        documentBuilder.add(decorator: ModelDecorator(model: order))
        documentBuilder.add(decorator: ConflictResolutionDecorator())
        let document = documentBuilder.build()
        let documentStringValue = """
        mutation CreateCustomerOrder($input: CreateCustomerOrderInput!) {
          createCustomerOrder(input: $input) {
            id
            email
            orderId
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
        documentBuilder.add(decorator: ModelDecorator(model: order))
        documentBuilder.add(decorator: ConflictResolutionDecorator(version: 1, lastSync: nil))
        let document = documentBuilder.build()
        let documentStringValue = """
        mutation UpdateCustomerOrder($input: UpdateCustomerOrderInput!) {
          updateCustomerOrder(input: $input) {
            id
            email
            orderId
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
        documentBuilder.add(decorator: ConflictResolutionDecorator(version: 1, lastSync: nil))
        let document = documentBuilder.build()
        let documentStringValue = """
        mutation DeleteCustomerOrder($input: DeleteCustomerOrderInput!) {
          deleteCustomerOrder(input: $input) {
            id
            email
            orderId
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

    func testDeleteMutationGraphQLRequestWithDateInPK() throws {
        do {
            let datetime = try Temporal.DateTime(iso8601String: "2020-01-20T08:00")
            let customer = CustomerWithDateInPK(dob: datetime, firstName: "John", lastName: "Doe")
            var documentBuilder = ModelBasedGraphQLDocumentBuilder(modelName: customer.modelName,
                                                                   operationType: .mutation)
            documentBuilder.add(decorator: DirectiveNameDecorator(type: .delete))
            documentBuilder.add(decorator: ModelIdDecorator(model: customer))
            documentBuilder.add(decorator: ConflictResolutionDecorator(version: 1, lastSync: nil))
            let document = documentBuilder.build()
            let documentStringValue = """
                mutation DeleteCustomerWithDateInPK($input: DeleteCustomerWithDateInPKInput!) {
                  deleteCustomerWithDateInPK(input: $input) {
                    id
                    createdAt
                    dob
                    firstName
                    lastName
                    updatedAt
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

            let request = GraphQLRequest<MutationSyncResult>.deleteMutation(of: customer,
                                                                            modelSchema: customer.schema,
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

            XCTAssertEqual(input["id"] as? String, customer.id)
            XCTAssertEqual(input["dob"] as? String, customer.dob.iso8601String)
            XCTAssertEqual(input["_version"] as? Int, 1)

            XCTAssertEqual(input["id"] as? String, expectedInput["id"] as? String)
            XCTAssertEqual(input["dob"] as? String, expectedInput["dob"] as? String)
            XCTAssertEqual(input["_version"] as? Int, expectedInput["_version"] as? Int)
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    func testOnCreateSubscriptionGraphQLRequestWithDateInPK() throws {
        do {
            let datetime = try Temporal.DateTime(iso8601String: "2020-01-20T08:00")
            let customer = CustomerWithDateInPK(dob: datetime, firstName: "John", lastName: "Doe")
            var documentBuilder = ModelBasedGraphQLDocumentBuilder(modelName: customer.modelName,
                                                                   operationType: .subscription)
            documentBuilder.add(decorator: DirectiveNameDecorator(type: .onCreate))
            documentBuilder.add(decorator: ConflictResolutionDecorator())
            let document = documentBuilder.build()
            let documentStringValue = """
                subscription OnCreateCustomerWithDateInPK {
                  onCreateCustomerWithDateInPK {
                    id
                    createdAt
                    dob
                    firstName
                    lastName
                    updatedAt
                    __typename
                    _version
                    _deleted
                    _lastChangedAt
                  }
                }
                """
            XCTAssertEqual(document.stringValue, documentStringValue)

            let request = GraphQLRequest<MutationSyncResult>.subscription(to: CustomerWithDateInPK.self,
                                                                          subscriptionType: .onCreate)
            XCTAssertEqual(document.stringValue, request.document)
            XCTAssertEqual(documentStringValue, request.document)
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    func testSyncQueryGraphQLRequestWithDateInPK() throws {
        let nextToken = "nextToken"
        let limit = 100
        let lastSync = 123
        var documentBuilder = ModelBasedGraphQLDocumentBuilder(modelName: CustomerWithDateInPK.modelName,
                                                               operationType: .query)
        documentBuilder.add(decorator: DirectiveNameDecorator(type: .sync))
        documentBuilder.add(decorator: PaginationDecorator(limit: limit, nextToken: nextToken))
        documentBuilder.add(decorator: ConflictResolutionDecorator(lastSync: lastSync))
        let document = documentBuilder.build()
        let documentStringValue = """
        query SyncCustomerWithDateInPKs($lastSync: AWSTimestamp, $limit: Int, $nextToken: String) {
          syncCustomerWithDateInPKs(lastSync: $lastSync, limit: $limit, nextToken: $nextToken) {
            items {
              id
              createdAt
              dob
              firstName
              lastName
              updatedAt
              __typename
              _version
              _deleted
              _lastChangedAt
            }
            nextToken
            startedAt
          }
        }
        """
        XCTAssertEqual(document.stringValue, documentStringValue)

        let request = GraphQLRequest<SyncQueryResult>.syncQuery(modelSchema: CustomerWithDateInPK.schema,
                                                                limit: limit,
                                                                nextToken: nextToken,
                                                                lastSync: lastSync)

        XCTAssertEqual(document.stringValue, request.document)
        XCTAssertEqual(documentStringValue, request.document)
        XCTAssert(request.responseType == SyncQueryResult.self)
        guard let variables = request.variables else {
            XCTFail("The request doesn't contain variables")
            return
        }
        XCTAssertNotNil(variables["limit"])
        XCTAssertEqual(variables["limit"] as? Int, limit)
        XCTAssertNotNil(variables["nextToken"])
        XCTAssertEqual(variables["nextToken"] as? String, nextToken)
        XCTAssertNotNil(variables["lastSync"])
        XCTAssertEqual(variables["lastSync"] as? Int, lastSync)
    }
}
