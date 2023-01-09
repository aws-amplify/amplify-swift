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

// swiftlint:disable type_body_length
class ModelWithOwnerFieldAuthRuleTests: XCTestCase {

    override func setUp() {
        ModelRegistry.register(modelType: ModelWithOwnerField.self)
    }

    override func tearDown() {
        ModelRegistry.reset()
    }

    // Since the owner field already exists on the model, ensure that it is not added again
    func testModelWithOwnerField_CreateMutation() {
        var documentBuilder = ModelBasedGraphQLDocumentBuilder(modelSchema: ModelWithOwnerField.schema,
                                                               operationType: .mutation)
        documentBuilder.add(decorator: DirectiveNameDecorator(type: .create))
        documentBuilder.add(decorator: AuthRuleDecorator(.mutation))
        let document = documentBuilder.build()
        let expectedQueryDocument = """
        mutation CreateModelWithOwnerField {
          createModelWithOwnerField {
            id
            author
            content
            __typename
          }
        }
        """
        XCTAssertEqual(document.name, "createModelWithOwnerField")
        XCTAssertEqual(document.stringValue, expectedQueryDocument)
        XCTAssertTrue(document.variables.isEmpty)
    }

    // Since the owner field already exists on the model, ensure that it is not added again
    func testModelWithOwnerField_DeleteMutation() {
        var documentBuilder = ModelBasedGraphQLDocumentBuilder(modelSchema: ModelWithOwnerField.schema,
                                                               operationType: .mutation)
        documentBuilder.add(decorator: DirectiveNameDecorator(type: .delete))
        documentBuilder.add(decorator: AuthRuleDecorator(.mutation))
        let document = documentBuilder.build()
        let expectedQueryDocument = """
        mutation DeleteModelWithOwnerField {
          deleteModelWithOwnerField {
            id
            author
            content
            __typename
          }
        }
        """
        XCTAssertEqual(document.name, "deleteModelWithOwnerField")
        XCTAssertEqual(document.stringValue, expectedQueryDocument)
        XCTAssertTrue(document.variables.isEmpty)
    }

    // Since the owner field already exists on the model, ensure that it is not added again
    func testModelWithOwnerField_UpdateMutation() {
        var documentBuilder = ModelBasedGraphQLDocumentBuilder(modelSchema: ModelWithOwnerField.schema,
                                                               operationType: .mutation)
        documentBuilder.add(decorator: DirectiveNameDecorator(type: .update))
        documentBuilder.add(decorator: AuthRuleDecorator(.mutation))
        let document = documentBuilder.build()
        let expectedQueryDocument = """
        mutation UpdateModelWithOwnerField {
          updateModelWithOwnerField {
            id
            author
            content
            __typename
          }
        }
        """
        XCTAssertEqual(document.name, "updateModelWithOwnerField")
        XCTAssertEqual(document.stringValue, expectedQueryDocument)
        XCTAssertTrue(document.variables.isEmpty)
    }

    // Since the owner field already exists on the model, ensure that it is not added again
    func testModelWithOwnerField_GetQuery() {
        var documentBuilder = ModelBasedGraphQLDocumentBuilder(modelSchema: ModelWithOwnerField.schema,
                                                               operationType: .query)
        documentBuilder.add(decorator: DirectiveNameDecorator(type: .get))
        documentBuilder.add(decorator: AuthRuleDecorator(.query))
        let document = documentBuilder.build()
        let expectedQueryDocument = """
        query GetModelWithOwnerField {
          getModelWithOwnerField {
            id
            author
            content
            __typename
          }
        }
        """
        XCTAssertEqual(document.name, "getModelWithOwnerField")
        XCTAssertEqual(document.stringValue, expectedQueryDocument)
        XCTAssertTrue(document.variables.isEmpty)
    }

    // Since the owner field already exists on the model, ensure that it is not added again
    func testModelWithOwnerField_ListQuery() {
        var documentBuilder = ModelBasedGraphQLDocumentBuilder(modelSchema: ModelWithOwnerField.schema,
                                                               operationType: .query)
        documentBuilder.add(decorator: DirectiveNameDecorator(type: .list))
        documentBuilder.add(decorator: PaginationDecorator())
        documentBuilder.add(decorator: AuthRuleDecorator(.query))
        let document = documentBuilder.build()
        let expectedQueryDocument = """
        query ListModelWithOwnerFields($limit: Int) {
          listModelWithOwnerFields(limit: $limit) {
            items {
              id
              author
              content
              __typename
            }
            nextToken
          }
        }
        """
        XCTAssertEqual(document.name, "listModelWithOwnerFields")
        XCTAssertEqual(document.stringValue, expectedQueryDocument)
    }

    func testModelWithOwnerField_SyncQuery() {
        var documentBuilder = ModelBasedGraphQLDocumentBuilder(modelSchema: ModelWithOwnerField.schema,
                                                               operationType: .query)
        documentBuilder.add(decorator: DirectiveNameDecorator(type: .sync))
        documentBuilder.add(decorator: PaginationDecorator())
        documentBuilder.add(decorator: ConflictResolutionDecorator(graphQLType: .query))
        documentBuilder.add(decorator: AuthRuleDecorator(.query))
        let document = documentBuilder.build()
        let expectedQueryDocument = """
        query SyncModelWithOwnerFields($limit: Int) {
          syncModelWithOwnerFields(limit: $limit) {
            items {
              id
              author
              content
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
        XCTAssertEqual(document.name, "syncModelWithOwnerFields")
        XCTAssertEqual(document.stringValue, expectedQueryDocument)
    }

    // The owner auth rule contains `.create` operation, requiring the subscription operation to contain the input
    func testModelWithOwnerField_OnCreateSubscription() {
        let claims = ["username": "user1",
                      "sub": "123e4567-dead-beef-a456-426614174000"] as IdentityClaimsDictionary
        var documentBuilder = ModelBasedGraphQLDocumentBuilder(modelSchema: ModelWithOwnerField.schema,
                                                               operationType: .subscription)
        documentBuilder.add(decorator: DirectiveNameDecorator(type: .onCreate))
        documentBuilder.add(decorator: AuthRuleDecorator(.subscription(.onCreate, claims)))
        let document = documentBuilder.build()
        let expectedQueryDocument = """
        subscription OnCreateModelWithOwnerField($author: String!) {
          onCreateModelWithOwnerField(author: $author) {
            id
            author
            content
            __typename
          }
        }
        """
        XCTAssertEqual(document.name, "onCreateModelWithOwnerField")
        XCTAssertEqual(document.stringValue, expectedQueryDocument)
        guard let variables = document.variables else {
            XCTFail("The document doesn't contain variables")
            return
        }
        XCTAssertEqual(variables["author"] as? String, "user1")
    }

    // The owner auth rule contains `.update` operation, requiring the subscription operation to contain the input
    func testModelWithOwnerField_OnUpdateSubscription() {
        let claims = ["username": "user1",
                      "sub": "123e4567-dead-beef-a456-426614174000"] as IdentityClaimsDictionary
        var documentBuilder = ModelBasedGraphQLDocumentBuilder(modelSchema: ModelWithOwnerField.schema,
                                                               operationType: .subscription)
        documentBuilder.add(decorator: DirectiveNameDecorator(type: .onUpdate))
        documentBuilder.add(decorator: AuthRuleDecorator(.subscription(.onUpdate, claims)))
        let document = documentBuilder.build()
        let expectedQueryDocument = """
        subscription OnUpdateModelWithOwnerField($author: String!) {
          onUpdateModelWithOwnerField(author: $author) {
            id
            author
            content
            __typename
          }
        }
        """
        XCTAssertEqual(document.name, "onUpdateModelWithOwnerField")
        XCTAssertEqual(document.stringValue, expectedQueryDocument)
        guard let variables = document.variables else {
            XCTFail("The document doesn't contain variables")
            return
        }
        XCTAssertEqual(variables["author"] as? String, "user1")
    }

    // The owner auth rule contains `.delete` operation, requiring the subscription operation to contain the input
    func testModelWithOwnerField_OnDeleteSubscription() {
        let claims = ["username": "user1",
                      "sub": "123e4567-dead-beef-a456-426614174000"] as IdentityClaimsDictionary
        var documentBuilder = ModelBasedGraphQLDocumentBuilder(modelSchema: ModelWithOwnerField.schema,
                                                               operationType: .subscription)
        documentBuilder.add(decorator: DirectiveNameDecorator(type: .onDelete))
        documentBuilder.add(decorator: AuthRuleDecorator(.subscription(.onDelete, claims)))
        let document = documentBuilder.build()
        let expectedQueryDocument = """
        subscription OnDeleteModelWithOwnerField($author: String!) {
          onDeleteModelWithOwnerField(author: $author) {
            id
            author
            content
            __typename
          }
        }
        """
        XCTAssertEqual(document.name, "onDeleteModelWithOwnerField")
        XCTAssertEqual(document.stringValue, expectedQueryDocument)
        guard let variables = document.variables else {
            XCTFail("The document doesn't contain variables")
            return
        }
        XCTAssertEqual(variables["author"] as? String, "user1")
    }

    func testModelWithMultipleAuthRules_Subscription() {
        var documentBuilder = ModelBasedGraphQLDocumentBuilder(modelSchema: ModelWithMultipleAuthRules.schema,
                                                               operationType: .subscription)
        documentBuilder.add(decorator: DirectiveNameDecorator(type: .onCreate))
        documentBuilder.add(decorator: AuthRuleDecorator(.subscription(.onCreate, nil)))
        let document = documentBuilder.build()
        let expectedQueryDocument = """
        subscription OnCreateModelWithMultipleAuthRules($author: String!) {
          onCreateModelWithMultipleAuthRules(author: $author) {
            id
            author
            content
            __typename
          }
        }
        """
        XCTAssertEqual(document.name, "onCreateModelWithMultipleAuthRules")
        XCTAssertEqual(document.stringValue, expectedQueryDocument)
    }

    func testModelWithMultipleAuthRulesAPIKey_Subscription() {
        var documentBuilder = ModelBasedGraphQLDocumentBuilder(modelSchema: ModelWithMultipleAuthRules.schema,
                                                               operationType: .subscription)
        documentBuilder.add(decorator: DirectiveNameDecorator(type: .onCreate))
        documentBuilder.add(decorator: AuthRuleDecorator(.subscription(.onCreate, nil),
                                                         authType: .apiKey))
        let document = documentBuilder.build()
        let expectedQueryDocument = """
        subscription OnCreateModelWithMultipleAuthRules {
          onCreateModelWithMultipleAuthRules {
            id
            author
            content
            __typename
          }
        }
        """
        XCTAssertEqual(document.name, "onCreateModelWithMultipleAuthRules")
        XCTAssertEqual(document.stringValue, expectedQueryDocument)
    }

    func testModelWithOIDCOwner_Subscription() {
        var documentBuilder = ModelBasedGraphQLDocumentBuilder(modelSchema: ModelWithOIDCOwnerField.schema,
                                                               operationType: .subscription)
        documentBuilder.add(decorator: DirectiveNameDecorator(type: .onCreate))
        documentBuilder.add(decorator: AuthRuleDecorator(.subscription(.onCreate, nil)))
        let document = documentBuilder.build()
        let expectedQueryDocument = """
        subscription OnCreateModelWithOIDCOwnerField($author: String!) {
          onCreateModelWithOIDCOwnerField(author: $author) {
            id
            author
            content
            __typename
          }
        }
        """
        XCTAssertEqual(document.name, "onCreateModelWithOIDCOwnerField")
        XCTAssertEqual(document.stringValue, expectedQueryDocument)
    }
}

// MARK: Test schemas

/*
 type ModelWithOwnerField
   @model
   @auth(rules: [ { allow: owner, ownerField: "author" } ])
 {
   id: ID!
   content: String!
   author: String
 }
*/
public struct ModelWithOwnerField: Model {
    public let id: String
    public var content: String
    public var author: String?
    public init(id: String = UUID().uuidString,
                content: String,
                author: String?) {
        self.id = id
        self.content = content
        self.author = author
    }
    public enum CodingKeys: String, ModelKey {
        case id
        case content
        case author
    }
    public static let keys = CodingKeys.self

    public static let schema = defineSchema { model in
        let modelWithOwnerField = ModelWithOwnerField.keys
        model.authRules = [
            rule(allow: .owner, ownerField: "author")
        ]
        model.fields(
            .id(),
            .field(modelWithOwnerField.content, is: .required, ofType: .string),
            .field(modelWithOwnerField.author, is: .optional, ofType: .string))
    }
}

/*
 type ModelWithOIDCOwnerField
   @model
   @auth(rules: [ { allow: owner, ownerField: "author" } ])
 {
   id: ID!
   content: String!
   author: String
 }
*/
public struct ModelWithOIDCOwnerField: Model {
    public let id: String
    public var content: String
    public var author: String?
    public init(id: String = UUID().uuidString,
                content: String,
                author: String?) {
        self.id = id
        self.content = content
        self.author = author
    }
    public enum CodingKeys: String, ModelKey {
        case id
        case content
        case author
    }
    public static let keys = CodingKeys.self

    public static let schema = defineSchema { model in
        let modelWithOwnerField = ModelWithOwnerField.keys
        model.authRules = [
            rule(allow: .owner, ownerField: "author", provider: .oidc)
        ]
        model.fields(
            .id(),
            .field(modelWithOwnerField.content, is: .required, ofType: .string),
            .field(modelWithOwnerField.author, is: .optional, ofType: .string))
    }
}

/*
 Example of model with multiple authorization rules,
 and one of them doesn't require an `owner`.

 type ModelWithOwnerField
   @model
   @auth(rules: [
        { allow: owner, ownerField: "author" },
        { allow: public, provider: "apiKey" }
    ])
 {
   id: ID!
   content: String!
   author: String
 }
*/
public struct ModelWithMultipleAuthRules: Model {
    public let id: String
    public var content: String
    public var author: String?
    public init(id: String = UUID().uuidString,
                content: String,
                author: String?) {
        self.id = id
        self.content = content
        self.author = author
    }
    public enum CodingKeys: String, ModelKey {
        case id
        case content
        case author
    }
    public static let keys = CodingKeys.self

    public static let schema = defineSchema { model in
        let modelWithMultipleAuthRules = ModelWithMultipleAuthRules.keys
        model.authRules = [
            rule(allow: .owner, ownerField: "author", provider: .userPools),
            rule(allow: .public, provider: .apiKey)
        ]
        model.fields(
            .id(),
            .field(modelWithMultipleAuthRules.content, is: .required, ofType: .string),
            .field(modelWithMultipleAuthRules.author, is: .optional, ofType: .string))
    }
}
