//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

import XCTest
@testable import Amplify
@testable import AmplifyTestCommon
@testable import AWSPluginsCore

class GraphQLRequestOwnerAndGroupTests: XCTestCase {

    override func setUp() {
        ModelRegistry.register(modelType: OGCScenarioBPost.self)
        ModelRegistry.register(modelType: OGCScenarioBMGroupPost.self)
    }

    override func tearDown() {
        ModelRegistry.reset()
    }

    func testOnCreateSubscriptionScenarioBInAdmins() {
        let modelType = OGCScenarioBPost.self as Model.Type
        let claims = ["username": "user1",
                      "sub": "123e4567-dead-beef-a456-426614174000",
                      "cognito:groups": ["Admins"]] as IdentityClaimsDictionary
        var documentBuilder = ModelBasedGraphQLDocumentBuilder(modelSchema: modelType.schema,
                                                               operationType: .subscription)
        documentBuilder.add(decorator: DirectiveNameDecorator(type: .onCreate))
        documentBuilder.add(decorator: ConflictResolutionDecorator(graphQLType: .subscription))
        documentBuilder.add(decorator: AuthRuleDecorator(.subscription(.onCreate, claims)))
        let document = documentBuilder.build()

        let documentStringValue = """
        subscription OnCreateOGCScenarioBPost {
          onCreateOGCScenarioBPost {
            id
            owner
            title
            __typename
            _version
            _deleted
            _lastChangedAt
          }
        }
        """
        let request = GraphQLRequest<MutationSyncResult>.subscription(to: modelType.schema,
                                                                      subscriptionType: .onCreate,
                                                                      claims: claims)
        XCTAssertEqual(document.stringValue, request.document)
        XCTAssertEqual(documentStringValue, request.document)
        XCTAssert(request.responseType == MutationSyncResult.self)
        XCTAssert(request.variables.isEmpty)
    }

    func testOnUpdateSubscriptionScenarioBInAdmins() {
        let modelType = OGCScenarioBPost.self as Model.Type
        let claims = ["username": "user1",
                      "sub": "123e4567-dead-beef-a456-426614174000",
                      "cognito:groups": ["Admins"]] as IdentityClaimsDictionary
        var documentBuilder = ModelBasedGraphQLDocumentBuilder(modelSchema: modelType.schema,
                                                               operationType: .subscription)
        documentBuilder.add(decorator: DirectiveNameDecorator(type: .onUpdate))
        documentBuilder.add(decorator: ConflictResolutionDecorator(graphQLType: .subscription))
        documentBuilder.add(decorator: AuthRuleDecorator(.subscription(.onUpdate, claims)))
        let document = documentBuilder.build()

        let documentStringValue = """
        subscription OnUpdateOGCScenarioBPost {
          onUpdateOGCScenarioBPost {
            id
            owner
            title
            __typename
            _version
            _deleted
            _lastChangedAt
          }
        }
        """
        let request = GraphQLRequest<MutationSyncResult>.subscription(to: modelType.schema,
                                                                      subscriptionType: .onUpdate,
                                                                      claims: claims)
        XCTAssertEqual(document.stringValue, request.document)
        XCTAssertEqual(documentStringValue, request.document)
        XCTAssert(request.responseType == MutationSyncResult.self)
        XCTAssert(request.variables.isEmpty)
    }

    func testOnDeleteSubscriptionScenarioBInAdmins() {
        let modelType = OGCScenarioBPost.self as Model.Type
        let claims = ["username": "user1",
                      "sub": "123e4567-dead-beef-a456-426614174000",
                      "cognito:groups": ["Admins"]] as IdentityClaimsDictionary
        var documentBuilder = ModelBasedGraphQLDocumentBuilder(modelSchema: modelType.schema,
                                                               operationType: .subscription)
        documentBuilder.add(decorator: DirectiveNameDecorator(type: .onDelete))
        documentBuilder.add(decorator: ConflictResolutionDecorator(graphQLType: .subscription))
        documentBuilder.add(decorator: AuthRuleDecorator(.subscription(.onDelete, claims)))
        let document = documentBuilder.build()

        let documentStringValue = """
        subscription OnDeleteOGCScenarioBPost {
          onDeleteOGCScenarioBPost {
            id
            owner
            title
            __typename
            _version
            _deleted
            _lastChangedAt
          }
        }
        """
        let request = GraphQLRequest<MutationSyncResult>.subscription(to: modelType.schema,
                                                                      subscriptionType: .onDelete,
                                                                      claims: claims)
        XCTAssertEqual(document.stringValue, request.document)
        XCTAssertEqual(documentStringValue, request.document)
        XCTAssert(request.responseType == MutationSyncResult.self)
        XCTAssert(request.variables.isEmpty)
    }

    func testOnCreateSubscriptionScenarioBInAdminsAndAnotherGroup() {
        let modelType = OGCScenarioBPost.self as Model.Type
        let claims = ["username": "user1",
                      "sub": "123e4567-dead-beef-a456-426614174000",
                      "cognito:groups": ["Admins", "GroupX"]] as IdentityClaimsDictionary
        var documentBuilder = ModelBasedGraphQLDocumentBuilder(modelSchema: modelType.schema,
                                                               operationType: .subscription)
        documentBuilder.add(decorator: DirectiveNameDecorator(type: .onCreate))
        documentBuilder.add(decorator: ConflictResolutionDecorator(graphQLType: .subscription))
        documentBuilder.add(decorator: AuthRuleDecorator(.subscription(.onCreate, claims)))
        let document = documentBuilder.build()

        let documentStringValue = """
        subscription OnCreateOGCScenarioBPost {
          onCreateOGCScenarioBPost {
            id
            owner
            title
            __typename
            _version
            _deleted
            _lastChangedAt
          }
        }
        """
        let request = GraphQLRequest<MutationSyncResult>.subscription(to: modelType.schema,
                                                                      subscriptionType: .onCreate,
                                                                      claims: claims)
        XCTAssertEqual(document.stringValue, request.document)
        XCTAssertEqual(documentStringValue, request.document)
        XCTAssert(request.responseType == MutationSyncResult.self)
        XCTAssert(request.variables.isEmpty)
    }

    func testOnCreateSubscriptionScenarioBNotInAdmins() {
        let modelType = OGCScenarioBPost.self as Model.Type
        let claims = ["username": "user1",
                      "sub": "123e4567-dead-beef-a456-426614174000",
                      "cognito:groups": ["GroupX"]] as IdentityClaimsDictionary
        var documentBuilder = ModelBasedGraphQLDocumentBuilder(modelSchema: modelType.schema,
                                                               operationType: .subscription)
        documentBuilder.add(decorator: DirectiveNameDecorator(type: .onCreate))
        documentBuilder.add(decorator: ConflictResolutionDecorator(graphQLType: .subscription))
        documentBuilder.add(decorator: AuthRuleDecorator(.subscription(.onCreate, claims)))
        let document = documentBuilder.build()

        let documentStringValue = """
        subscription OnCreateOGCScenarioBPost($owner: String!) {
          onCreateOGCScenarioBPost(owner: $owner) {
            id
            owner
            title
            __typename
            _version
            _deleted
            _lastChangedAt
          }
        }
        """
        let request = GraphQLRequest<MutationSyncResult>.subscription(to: modelType.schema,
                                                                      subscriptionType: .onCreate,
                                                                      claims: claims)
        XCTAssertEqual(document.stringValue, request.document)
        XCTAssertEqual(documentStringValue, request.document)
        XCTAssert(request.responseType == MutationSyncResult.self)
        guard let variables = request.variables else {
            XCTFail("The request doesn't contain variables")
            return
        }
        guard let input = variables["owner"] as? String else {
            XCTFail("The document variables property doesn't contain a valid input")
            return
        }
        XCTAssertEqual(input, "user1")
    }

    func testOnUpdateSubscriptionScenarioBNotInAdmins() {
        let modelType = OGCScenarioBPost.self as Model.Type
        let claims = ["username": "user1",
                      "sub": "123e4567-dead-beef-a456-426614174000",
                      "cognito:groups": ["GroupX"]] as IdentityClaimsDictionary
        var documentBuilder = ModelBasedGraphQLDocumentBuilder(modelSchema: modelType.schema,
                                                               operationType: .subscription)
        documentBuilder.add(decorator: DirectiveNameDecorator(type: .onUpdate))
        documentBuilder.add(decorator: ConflictResolutionDecorator(graphQLType: .subscription))
        documentBuilder.add(decorator: AuthRuleDecorator(.subscription(.onUpdate, claims)))
        let document = documentBuilder.build()

        let documentStringValue = """
        subscription OnUpdateOGCScenarioBPost($owner: String!) {
          onUpdateOGCScenarioBPost(owner: $owner) {
            id
            owner
            title
            __typename
            _version
            _deleted
            _lastChangedAt
          }
        }
        """
        let request = GraphQLRequest<MutationSyncResult>.subscription(to: modelType.schema,
                                                                      subscriptionType: .onUpdate,
                                                                      claims: claims)
        XCTAssertEqual(document.stringValue, request.document)
        XCTAssertEqual(documentStringValue, request.document)
        XCTAssert(request.responseType == MutationSyncResult.self)
        guard let variables = request.variables else {
            XCTFail("The request doesn't contain variables")
            return
        }
        guard let input = variables["owner"] as? String else {
            XCTFail("The document variables property doesn't contain a valid input")
            return
        }
        XCTAssertEqual(input, "user1")
    }

    func testOnDeleteSubscriptionScenarioBNotInAdmins() {
        let modelType = OGCScenarioBPost.self as Model.Type
        let claims = ["username": "user1",
                      "sub": "123e4567-dead-beef-a456-426614174000",
                      "cognito:groups": ["GroupX"]] as IdentityClaimsDictionary
        var documentBuilder = ModelBasedGraphQLDocumentBuilder(modelSchema: modelType.schema,
                                                               operationType: .subscription)
        documentBuilder.add(decorator: DirectiveNameDecorator(type: .onDelete))
        documentBuilder.add(decorator: ConflictResolutionDecorator(graphQLType: .subscription))
        documentBuilder.add(decorator: AuthRuleDecorator(.subscription(.onDelete, claims)))
        let document = documentBuilder.build()

        let documentStringValue = """
        subscription OnDeleteOGCScenarioBPost($owner: String!) {
          onDeleteOGCScenarioBPost(owner: $owner) {
            id
            owner
            title
            __typename
            _version
            _deleted
            _lastChangedAt
          }
        }
        """
        let request = GraphQLRequest<MutationSyncResult>.subscription(to: modelType.schema,
                                                                      subscriptionType: .onDelete,
                                                                      claims: claims)
        XCTAssertEqual(document.stringValue, request.document)
        XCTAssertEqual(documentStringValue, request.document)
        XCTAssert(request.responseType == MutationSyncResult.self)
        guard let variables = request.variables else {
            XCTFail("The request doesn't contain variables")
            return
        }
        guard let input = variables["owner"] as? String else {
            XCTFail("The document variables property doesn't contain a valid input")
            return
        }
        XCTAssertEqual(input, "user1")
    }

    func testOnDeleteSubscriptionScenarioBNoGroupClaim() {
        let modelType = OGCScenarioBPost.self as Model.Type
        let claims = ["username": "user1",
                      "sub": "123e4567-dead-beef-a456-426614174000"] as IdentityClaimsDictionary
        // Specifically, leave this out:
        //                     "cognito:groups": ["GroupX"]]
        var documentBuilder = ModelBasedGraphQLDocumentBuilder(modelSchema: modelType.schema,
                                                               operationType: .subscription)
        documentBuilder.add(decorator: DirectiveNameDecorator(type: .onDelete))
        documentBuilder.add(decorator: ConflictResolutionDecorator(graphQLType: .subscription))
        documentBuilder.add(decorator: AuthRuleDecorator(.subscription(.onDelete, claims)))
        let document = documentBuilder.build()

        let documentStringValue = """
        subscription OnDeleteOGCScenarioBPost($owner: String!) {
          onDeleteOGCScenarioBPost(owner: $owner) {
            id
            owner
            title
            __typename
            _version
            _deleted
            _lastChangedAt
          }
        }
        """
        let request = GraphQLRequest<MutationSyncResult>.subscription(to: modelType.schema,
                                                                      subscriptionType: .onDelete,
                                                                      claims: claims)
        XCTAssertEqual(document.stringValue, request.document)
        XCTAssertEqual(documentStringValue, request.document)
        XCTAssert(request.responseType == MutationSyncResult.self)
        guard let variables = request.variables else {
            XCTFail("The request doesn't contain variables")
            return
        }
        guard let input = variables["owner"] as? String else {
            XCTFail("The document variables property doesn't contain a valid input")
            return
        }
        XCTAssertEqual(input, "user1")
    }

    func testOnCreateSubscriptionScenarioBMGroupInAdmins() {
        let modelType = OGCScenarioBMGroupPost.self as Model.Type
        let claims = ["username": "user1",
                      "sub": "123e4567-dead-beef-a456-426614174000",
                      "cognito:groups": ["Admins"]] as IdentityClaimsDictionary
        var documentBuilder = ModelBasedGraphQLDocumentBuilder(modelSchema: modelType.schema,
                                                               operationType: .subscription)
        documentBuilder.add(decorator: DirectiveNameDecorator(type: .onCreate))
        documentBuilder.add(decorator: ConflictResolutionDecorator(graphQLType: .subscription))
        documentBuilder.add(decorator: AuthRuleDecorator(.subscription(.onCreate, claims)))
        let document = documentBuilder.build()

        let documentStringValue = """
        subscription OnCreateOGCScenarioBMGroupPost {
          onCreateOGCScenarioBMGroupPost {
            id
            owner
            title
            __typename
            _version
            _deleted
            _lastChangedAt
          }
        }
        """
        let request = GraphQLRequest<MutationSyncResult>.subscription(to: modelType.schema,
                                                                      subscriptionType: .onCreate,
                                                                      claims: claims)
        XCTAssertEqual(document.stringValue, request.document)
        XCTAssertEqual(documentStringValue, request.document)
        XCTAssert(request.responseType == MutationSyncResult.self)
        XCTAssert(request.variables.isEmpty)
    }

    func testOnCreateSubscriptionScenarioBMGroupInAdminsAndAnotherGroup() {
        let modelType = OGCScenarioBMGroupPost.self as Model.Type
        let claims = ["username": "user1",
                      "sub": "123e4567-dead-beef-a456-426614174000",
                      "cognito:groups": ["Admins", "GroupX"]] as IdentityClaimsDictionary
        var documentBuilder = ModelBasedGraphQLDocumentBuilder(modelSchema: modelType.schema,
                                                               operationType: .subscription)
        documentBuilder.add(decorator: DirectiveNameDecorator(type: .onCreate))
        documentBuilder.add(decorator: ConflictResolutionDecorator(graphQLType: .subscription))
        documentBuilder.add(decorator: AuthRuleDecorator(.subscription(.onCreate, claims)))
        let document = documentBuilder.build()

        let documentStringValue = """
        subscription OnCreateOGCScenarioBMGroupPost {
          onCreateOGCScenarioBMGroupPost {
            id
            owner
            title
            __typename
            _version
            _deleted
            _lastChangedAt
          }
        }
        """
        let request = GraphQLRequest<MutationSyncResult>.subscription(to: modelType.schema,
                                                                      subscriptionType: .onCreate,
                                                                      claims: claims)
        XCTAssertEqual(document.stringValue, request.document)
        XCTAssertEqual(documentStringValue, request.document)
        XCTAssert(request.responseType == MutationSyncResult.self)
        XCTAssert(request.variables.isEmpty)
    }
}
