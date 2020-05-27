//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
@testable import Amplify
@testable import AmplifyTestCommon
@testable import AWSPluginsCore
/*
 type ModelMultipleOwner @model
   @auth(rules: [

     # Defaults to use the "owner" field.
     { allow: owner },
     { allow: owner, ownerField: "editors", operations: [update, read] }
   ]) {
   id: ID!
   content: String
   editors: [String]
 }
*/
public struct ModelMultipleOwner: Model {
    public let id: String
    public var content: String
    public var editors: [String]?
    public init(id: String = UUID().uuidString,
                content: String,
                editors: [String]? = []) {
        self.id = id
        self.content = content
        self.editors = editors
    }
    public enum CodingKeys: String, ModelKey {
        case id
        case content
        case editors
    }
    public static let keys = CodingKeys.self

    public static let schema = defineSchema { model in
        let modelMultipleOwner = ModelMultipleOwner.keys
        model.authRules = [
            rule(allow: .owner),
            rule(allow: .owner, ownerField: "editors", operations: [.update, .read])
        ]
        model.fields(
            .id(),
            .field(modelMultipleOwner.content, is: .required, ofType: .string),
            .field(modelMultipleOwner.editors, is: .optional, ofType: .customType([String].self))
        )
    }
}

class ModelMultipleOwnerAuthRuleTests: XCTestCase {

    override func setUp() {
        ModelRegistry.register(modelType: ModelMultipleOwner.self)
    }

    override func tearDown() {
        ModelRegistry.reset()
    }

    // Ensure that the `owner` field is added to the model fields
    func testModelMultipleOwner_CreateMutation() {
        var documentBuilder = ModelBasedGraphQLDocumentBuilder(modelType: ModelMultipleOwner.self,
                                                               operationType: .mutation)
        documentBuilder.add(decorator: DirectiveNameDecorator(type: .create))
        documentBuilder.add(decorator: AuthRuleDecorator(.mutation))
        let document = documentBuilder.build()
        let expectedQueryDocument = """
        mutation CreateModelMultipleOwner {
          createModelMultipleOwner {
            id
            content
            editors
            __typename
            owner
          }
        }
        """
        XCTAssertEqual(document.name, "createModelMultipleOwner")
        XCTAssertEqual(document.stringValue, expectedQueryDocument)
        XCTAssertTrue(document.variables.isEmpty)
    }

    // Ensure that the `owner` field is added to the model fields
    func testModelMultipleOwner_DeleteMutation() {
        var documentBuilder = ModelBasedGraphQLDocumentBuilder(modelType: ModelMultipleOwner.self,
                                                               operationType: .mutation)
        documentBuilder.add(decorator: DirectiveNameDecorator(type: .delete))
        documentBuilder.add(decorator: AuthRuleDecorator(.mutation))
        let document = documentBuilder.build()
        let expectedQueryDocument = """
        mutation DeleteModelMultipleOwner {
          deleteModelMultipleOwner {
            id
            content
            editors
            __typename
            owner
          }
        }
        """
        XCTAssertEqual(document.name, "deleteModelMultipleOwner")
        XCTAssertEqual(document.stringValue, expectedQueryDocument)
        XCTAssertTrue(document.variables.isEmpty)
    }

    // Ensure that the `owner` field is added to the model fields
    func testModelMultipleOwner_UpdateMutation() {
        var documentBuilder = ModelBasedGraphQLDocumentBuilder(modelType: ModelMultipleOwner.self,
                                                               operationType: .mutation)
        documentBuilder.add(decorator: DirectiveNameDecorator(type: .update))
        documentBuilder.add(decorator: AuthRuleDecorator(.mutation))
        let document = documentBuilder.build()
        let expectedQueryDocument = """
        mutation UpdateModelMultipleOwner {
          updateModelMultipleOwner {
            id
            content
            editors
            __typename
            owner
          }
        }
        """
        XCTAssertEqual(document.name, "updateModelMultipleOwner")
        XCTAssertEqual(document.stringValue, expectedQueryDocument)
        XCTAssertTrue(document.variables.isEmpty)
    }

    // Ensure that the `owner` field is added to the model fields
    func testModelMultipleOwner_GetQuery() {
        var documentBuilder = ModelBasedGraphQLDocumentBuilder(modelType: ModelMultipleOwner.self,
                                                               operationType: .query)
        documentBuilder.add(decorator: DirectiveNameDecorator(type: .get))
        documentBuilder.add(decorator: AuthRuleDecorator(.query))
        let document = documentBuilder.build()
        let expectedQueryDocument = """
        query GetModelMultipleOwner {
          getModelMultipleOwner {
            id
            content
            editors
            __typename
            owner
          }
        }
        """
        XCTAssertEqual(document.name, "getModelMultipleOwner")
        XCTAssertEqual(document.stringValue, expectedQueryDocument)
        XCTAssertTrue(document.variables.isEmpty)
    }

    // A List query is a paginated selection set, make sure the `owner` field is added to the model fields
    func testModelMultipleOwner_ListQuery() {
        var documentBuilder = ModelBasedGraphQLDocumentBuilder(modelType: ModelMultipleOwner.self,
                                                               operationType: .query)
        documentBuilder.add(decorator: DirectiveNameDecorator(type: .list))
        documentBuilder.add(decorator: PaginationDecorator())
        documentBuilder.add(decorator: AuthRuleDecorator(.query))
        let document = documentBuilder.build()
        let expectedQueryDocument = """
        query ListModelMultipleOwners($limit: Int) {
          listModelMultipleOwners(limit: $limit) {
            items {
              id
              content
              editors
              __typename
              owner
            }
            nextToken
          }
        }
        """
        XCTAssertEqual(document.name, "listModelMultipleOwners")
        XCTAssertEqual(document.stringValue, expectedQueryDocument)
    }

    func testModelMultipleOwner_SyncQuery() {
        var documentBuilder = ModelBasedGraphQLDocumentBuilder(modelType: ModelMultipleOwner.self,
                                                               operationType: .query)
        documentBuilder.add(decorator: DirectiveNameDecorator(type: .sync))
        documentBuilder.add(decorator: PaginationDecorator())
        documentBuilder.add(decorator: ConflictResolutionDecorator())
        documentBuilder.add(decorator: AuthRuleDecorator(.query))
        let document = documentBuilder.build()
        let expectedQueryDocument = """
        query SyncModelMultipleOwners($limit: Int) {
          syncModelMultipleOwners(limit: $limit) {
            items {
              id
              content
              editors
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
        XCTAssertEqual(document.name, "syncModelMultipleOwners")
        XCTAssertEqual(document.stringValue, expectedQueryDocument)
    }

    // Only the 'owner' inherently has `.create` operation, requiring the subscription operation to contain the input
    func testModelMultipleOwner_OnCreateSubscription() {
        var documentBuilder = ModelBasedGraphQLDocumentBuilder(modelType: ModelMultipleOwner.self,
                                                               operationType: .subscription)
        documentBuilder.add(decorator: DirectiveNameDecorator(type: .onCreate))
        documentBuilder.add(decorator: AuthRuleDecorator(.subscription(.onCreate, "111")))
        let document = documentBuilder.build()
        let expectedQueryDocument = """
        subscription OnCreateModelMultipleOwner($owner: String!) {
          onCreateModelMultipleOwner(owner: $owner) {
            id
            content
            editors
            __typename
            owner
          }
        }
        """
        XCTAssertEqual(document.name, "onCreateModelMultipleOwner")
        XCTAssertEqual(document.stringValue, expectedQueryDocument)
        guard let variables = document.variables else {
            XCTFail("The document doesn't contain variables")
            return
        }
        XCTAssertEqual(variables["owner"] as? String, "111")
    }

    // Each owner with `.update` operation requires the ownerField on the corresponding subscription operation
    func testModelMultipleOwner_OnUpdateSubscription() {
        var documentBuilder = ModelBasedGraphQLDocumentBuilder(modelType: ModelMultipleOwner.self,
                                                               operationType: .subscription)
        documentBuilder.add(decorator: DirectiveNameDecorator(type: .onUpdate))
        documentBuilder.add(decorator: AuthRuleDecorator(.subscription(.onUpdate, "111")))
        let document = documentBuilder.build()
        let expectedQueryDocument = """
        subscription OnUpdateModelMultipleOwner($editors: String!, $owner: String!) {
          onUpdateModelMultipleOwner(editors: $editors, owner: $owner) {
            id
            content
            editors
            __typename
            owner
          }
        }
        """
        XCTAssertEqual(document.name, "onUpdateModelMultipleOwner")
        XCTAssertEqual(document.stringValue, expectedQueryDocument)
        guard let variables = document.variables else {
            XCTFail("The document doesn't contain variables")
            return
        }
        XCTAssertEqual(variables["owner"] as? String, "111")
        XCTAssertEqual(variables["editors"] as? String, "111")
    }

    // Only the 'owner' inherently has `.delete` operation, requiring the subscription operation to contain the input
    func testModelMultipleOwner_OnDeleteSubscription() {
        var documentBuilder = ModelBasedGraphQLDocumentBuilder(modelType: ModelMultipleOwner.self,
                                                               operationType: .subscription)
        documentBuilder.add(decorator: DirectiveNameDecorator(type: .onDelete))
        documentBuilder.add(decorator: AuthRuleDecorator(.subscription(.onDelete, "111")))
        let document = documentBuilder.build()
        let expectedQueryDocument = """
        subscription OnDeleteModelMultipleOwner($owner: String!) {
          onDeleteModelMultipleOwner(owner: $owner) {
            id
            content
            editors
            __typename
            owner
          }
        }
        """
        XCTAssertEqual(document.name, "onDeleteModelMultipleOwner")
        XCTAssertEqual(document.stringValue, expectedQueryDocument)
        guard let variables = document.variables else {
            XCTFail("The document doesn't contain variables")
            return
        }
        XCTAssertEqual(variables["owner"] as? String, "111")
    }
}
