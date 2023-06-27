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

/*
 type ModelReadUpdate
   @model
   @auth(rules: [ { allow: owner, operations: [create, delete] } ])
 {
   id: ID!
   description: String!
 }
*/
public struct ModelReadUpdateField: Model {
    public let id: String
    public var content: String
    public init(id: String = UUID().uuidString,
                content: String) {
        self.id = id
        self.content = content
    }
    public enum CodingKeys: String, ModelKey {
        case id
        case content
    }
    public static let keys = CodingKeys.self

    public static let schema = defineSchema { model in
        let modelReadUpdateField = ModelReadUpdateField.keys
        model.authRules = [
            rule(allow: .owner, operations: [.create, .delete])
        ]
        model.fields(
            .id(),
            .field(modelReadUpdateField.content, is: .required, ofType: .string))
    }
}

class ModelReadUpdateAuthRuleTests: XCTestCase {

    override func setUp() {
        ModelRegistry.register(modelType: ModelReadUpdateField.self)
    }

    override func tearDown() {
        ModelRegistry.reset()
    }

    // Ensure that the `owner` field is added to the model fields
    func testModelReadUpdateField_CreateMutation() {
        var documentBuilder = ModelBasedGraphQLDocumentBuilder(modelSchema: ModelReadUpdateField.schema,
                                                               operationType: .mutation)
        documentBuilder.add(decorator: DirectiveNameDecorator(type: .create))
        documentBuilder.add(decorator: AuthRuleDecorator(.mutation))
        let document = documentBuilder.build()
        let expectedQueryDocument = """
        mutation CreateModelReadUpdateField {
          createModelReadUpdateField {
            id
            content
            __typename
            owner
          }
        }
        """
        XCTAssertEqual(document.name, "createModelReadUpdateField")
        XCTAssertEqual(document.stringValue, expectedQueryDocument)
        XCTAssertTrue(document.variables.isEmpty)
    }

    // Ensure that the `owner` field is added to the model fields
    func testModelReadUpdateField_DeleteMutation() {
        var documentBuilder = ModelBasedGraphQLDocumentBuilder(modelSchema: ModelReadUpdateField.schema,
                                                               operationType: .mutation)
        documentBuilder.add(decorator: DirectiveNameDecorator(type: .delete))
        documentBuilder.add(decorator: AuthRuleDecorator(.mutation))
        let document = documentBuilder.build()
        let expectedQueryDocument = """
        mutation DeleteModelReadUpdateField {
          deleteModelReadUpdateField {
            id
            content
            __typename
            owner
          }
        }
        """
        XCTAssertEqual(document.name, "deleteModelReadUpdateField")
        XCTAssertEqual(document.stringValue, expectedQueryDocument)
        XCTAssertTrue(document.variables.isEmpty)
    }

    // Ensure that the `owner` field is added to the model fields
    func testModelReadUpdateField_UpdateMutation() {
        var documentBuilder = ModelBasedGraphQLDocumentBuilder(modelSchema: ModelReadUpdateField.schema,
                                                               operationType: .mutation)
        documentBuilder.add(decorator: DirectiveNameDecorator(type: .update))
        documentBuilder.add(decorator: AuthRuleDecorator(.mutation))
        let document = documentBuilder.build()
        let expectedQueryDocument = """
        mutation UpdateModelReadUpdateField {
          updateModelReadUpdateField {
            id
            content
            __typename
            owner
          }
        }
        """
        XCTAssertEqual(document.name, "updateModelReadUpdateField")
        XCTAssertEqual(document.stringValue, expectedQueryDocument)
        XCTAssertTrue(document.variables.isEmpty)
    }

    // Ensure that the `owner` field is added to the model fields
    func testModelReadUpdateField_GetQuery() {
        var documentBuilder = ModelBasedGraphQLDocumentBuilder(modelSchema: ModelReadUpdateField.schema,
                                                               operationType: .query)
        documentBuilder.add(decorator: DirectiveNameDecorator(type: .get))
        documentBuilder.add(decorator: AuthRuleDecorator(.query))
        let document = documentBuilder.build()
        let expectedQueryDocument = """
        query GetModelReadUpdateField {
          getModelReadUpdateField {
            id
            content
            __typename
            owner
          }
        }
        """
        XCTAssertEqual(document.name, "getModelReadUpdateField")
        XCTAssertEqual(document.stringValue, expectedQueryDocument)
        XCTAssertTrue(document.variables.isEmpty)
    }

    // A List query is a paginated selection set, make sure the `owner` field is added to the model fields
    func testModelReadUpdateField_ListQuery() {
        var documentBuilder = ModelBasedGraphQLDocumentBuilder(modelSchema: ModelReadUpdateField.schema,
                                                               operationType: .query)
        documentBuilder.add(decorator: DirectiveNameDecorator(type: .list))
        documentBuilder.add(decorator: PaginationDecorator())
        documentBuilder.add(decorator: AuthRuleDecorator(.query))
        let document = documentBuilder.build()
        let expectedQueryDocument = """
        query ListModelReadUpdateFields($limit: Int) {
          listModelReadUpdateFields(limit: $limit) {
            items {
              id
              content
              __typename
              owner
            }
            nextToken
          }
        }
        """
        XCTAssertEqual(document.name, "listModelReadUpdateFields")
        XCTAssertEqual(document.stringValue, expectedQueryDocument)
    }

    func testModelReadUpdateField_SyncQuery() {
        var documentBuilder = ModelBasedGraphQLDocumentBuilder(modelSchema: ModelReadUpdateField.schema,
                                                               operationType: .query)
        documentBuilder.add(decorator: DirectiveNameDecorator(type: .sync))
        documentBuilder.add(decorator: PaginationDecorator())
        documentBuilder.add(decorator: ConflictResolutionDecorator())
        documentBuilder.add(decorator: AuthRuleDecorator(.query))
        let document = documentBuilder.build()
        let expectedQueryDocument = """
        query SyncModelReadUpdateFields($limit: Int) {
          syncModelReadUpdateFields(limit: $limit) {
            items {
              id
              content
              __typename
              _version
              _deleted
              _lastChangedAt
              owner
            }
            nextToken
            startedAt
          }
        }
        """
        XCTAssertEqual(document.name, "syncModelReadUpdateFields")
        XCTAssertEqual(document.stringValue, expectedQueryDocument)
    }

    // The owner auth rule contains `.create` operation, requiring the subscription operation to contain the input
    func testModelReadUpdateField_OnCreateSubscription() {
        let claims = ["username": "user1",
                      "sub": "123e4567-dead-beef-a456-426614174000"] as IdentityClaimsDictionary
        var documentBuilder = ModelBasedGraphQLDocumentBuilder(modelSchema: ModelReadUpdateField.schema,
                                                               operationType: .subscription)
        documentBuilder.add(decorator: DirectiveNameDecorator(type: .onCreate))
        documentBuilder.add(decorator: AuthRuleDecorator(.subscription(.onCreate, claims)))
        let document = documentBuilder.build()
        let expectedQueryDocument = """
        subscription OnCreateModelReadUpdateField {
          onCreateModelReadUpdateField {
            id
            content
            __typename
            owner
          }
        }
        """
        XCTAssertEqual(document.name, "onCreateModelReadUpdateField")
        XCTAssertEqual(document.stringValue, expectedQueryDocument)
        XCTAssert(document.variables.isEmpty)
    }

    // Others can `.update` this model, which means the update subscription does not require owner input
    func testModelReadUpdateField_OnUpdateSubscription() {
        let claims = ["username": "user1",
                      "sub": "123e4567-dead-beef-a456-426614174000"] as IdentityClaimsDictionary
        var documentBuilder = ModelBasedGraphQLDocumentBuilder(modelSchema: ModelReadUpdateField.schema,
                                                               operationType: .subscription)
        documentBuilder.add(decorator: DirectiveNameDecorator(type: .onUpdate))
        documentBuilder.add(decorator: AuthRuleDecorator(.subscription(.onUpdate, claims)))
        let document = documentBuilder.build()
        let expectedQueryDocument = """
        subscription OnUpdateModelReadUpdateField {
          onUpdateModelReadUpdateField {
            id
            content
            __typename
            owner
          }
        }
        """
        XCTAssertEqual(document.name, "onUpdateModelReadUpdateField")
        XCTAssertEqual(document.stringValue, expectedQueryDocument)
    }

    // The owner auth rule contains `.delete` operation, requiring the subscription operation to contain the input
    func testModelReadUpdateField_OnDeleteSubscription() {
        let claims = ["username": "user1",
                      "sub": "123e4567-dead-beef-a456-426614174000"] as IdentityClaimsDictionary
        var documentBuilder = ModelBasedGraphQLDocumentBuilder(modelSchema: ModelReadUpdateField.schema,
                                                               operationType: .subscription)
        documentBuilder.add(decorator: DirectiveNameDecorator(type: .onDelete))
        documentBuilder.add(decorator: AuthRuleDecorator(.subscription(.onDelete, claims)))
        let document = documentBuilder.build()
        let expectedQueryDocument = """
        subscription OnDeleteModelReadUpdateField {
          onDeleteModelReadUpdateField {
            id
            content
            __typename
            owner
          }
        }
        """
        XCTAssertEqual(document.name, "onDeleteModelReadUpdateField")
        XCTAssertEqual(document.stringValue, expectedQueryDocument)
        XCTAssert(document.variables.isEmpty)
    }

}
