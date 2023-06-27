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

// swiftlint:disable type_name
class GraphQLRequestSyncCustomPrimaryKeyWithMultipleFieldsTests: XCTestCase {

    override func setUp() {
        ModelRegistry.register(modelType: CustomerWithMultipleFieldsinPK.self)
    }

    override func tearDown() {
        ModelRegistry.reset()
    }

    func testDeleteMutationGraphQLRequestWithDateInPK() throws {
        let customer = CustomerWithMultipleFieldsinPK(dob: Temporal.DateTime.now(),
                                                      date: Temporal.Date.now(),
                                                      time: Temporal.Time.now(),
                                                      phoneNumber: 1_234_567,
                                                      priority: Priority.high,
                                                      height: 6.1,
                                                      firstName: "John",
                                                      lastName: "Doe")
        var documentBuilder = ModelBasedGraphQLDocumentBuilder(modelName: customer.modelName,
                                                               operationType: .mutation)
        documentBuilder.add(decorator: DirectiveNameDecorator(type: .delete))
        documentBuilder.add(decorator: ModelIdDecorator(model: customer))
        documentBuilder.add(decorator: ConflictResolutionDecorator(version: 1, lastSync: nil, graphQLType: .mutation))
        let document = documentBuilder.build()
        let documentStringValue = """
                mutation DeleteCustomerWithMultipleFieldsinPK($input: DeleteCustomerWithMultipleFieldsinPKInput!) {
                  deleteCustomerWithMultipleFieldsinPK(input: $input) {
                    id
                    dob
                    date
                    time
                    phoneNumber
                    priority
                    height
                    createdAt
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
        XCTAssertEqual(input["date"] as? String, customer.date.iso8601String)
        XCTAssertEqual(input["time"] as? String, customer.time.iso8601String)
        XCTAssertEqual(input["phoneNumber"] as? String, String(describing: customer.phoneNumber))
        XCTAssertEqual(input["priority"] as? String, customer.priority.rawValue)
        XCTAssertEqual(input["height"] as? String, String(describing: customer.height))
        XCTAssertEqual(input["_version"] as? Int, 1)

        XCTAssertEqual(input["id"] as? String, expectedInput["id"] as? String)
        XCTAssertEqual(input["dob"] as? String, expectedInput["dob"] as? String)
        XCTAssertEqual(input["date"] as? String, expectedInput["date"] as? String)
        XCTAssertEqual(input["time"] as? String, expectedInput["time"] as? String)
        XCTAssertEqual(input["phoneNumber"] as? String, expectedInput["phoneNumber"] as? String)
        XCTAssertEqual(input["priority"] as? String, expectedInput["priority"] as? String)
        XCTAssertEqual(input["height"] as? String, expectedInput["height"] as? String)
        XCTAssertEqual(input["_version"] as? Int, expectedInput["_version"] as? Int)
    }

    func testOnCreateSubscriptionGraphQLRequestWithDateInPK() throws {
        var documentBuilder = ModelBasedGraphQLDocumentBuilder(modelName: CustomerWithMultipleFieldsinPK.modelName,
                                                               operationType: .subscription)
        documentBuilder.add(decorator: DirectiveNameDecorator(type: .onCreate))
        documentBuilder.add(decorator: ConflictResolutionDecorator())
        let document = documentBuilder.build()
        let documentStringValue = """
                subscription OnCreateCustomerWithMultipleFieldsinPK {
                  onCreateCustomerWithMultipleFieldsinPK {
                    id
                    dob
                    date
                    time
                    phoneNumber
                    priority
                    height
                    createdAt
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

        let request = GraphQLRequest<MutationSyncResult>.subscription(to: CustomerWithMultipleFieldsinPK.self,
                                                                      subscriptionType: .onCreate)
        XCTAssertEqual(document.stringValue, request.document)
        XCTAssertEqual(documentStringValue, request.document)
    }

    func testSyncQueryGraphQLRequestWithDateInPK() throws {
        let nextToken = "nextToken"
        let limit = 100
        let lastSync = 123
        var documentBuilder = ModelBasedGraphQLDocumentBuilder(modelName: CustomerWithMultipleFieldsinPK.modelName,
                                                               operationType: .query)
        documentBuilder.add(decorator: DirectiveNameDecorator(type: .sync))
        documentBuilder.add(decorator: PaginationDecorator(limit: limit, nextToken: nextToken))
        documentBuilder.add(decorator: ConflictResolutionDecorator(lastSync: lastSync, graphQLType: .query))
        let document = documentBuilder.build()
        let documentStringValue = """
        query SyncCustomerWithMultipleFieldsinPKs($lastSync: AWSTimestamp, $limit: Int, $nextToken: String) {
          syncCustomerWithMultipleFieldsinPKs(lastSync: $lastSync, limit: $limit, nextToken: $nextToken) {
            items {
              id
              dob
              date
              time
              phoneNumber
              priority
              height
              createdAt
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

        let request = GraphQLRequest<SyncQueryResult>.syncQuery(modelSchema: CustomerWithMultipleFieldsinPK.schema,
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
