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

class GraphQLRequestAuthIdentityClaimTests: XCTestCase {

    override func setUp() async throws {
        ModelRegistry.register(modelType: ScenarioATest6Post.self)
    }

    override func tearDown() async throws {
        ModelRegistry.reset()
    }

    func testOnCreateSubscriptionGraphQLRequestCustomIdentityClaim() throws {
        let modelType = ScenarioATest6Post.self as Model.Type
        let claims = ["username": "user1",
                      "sub": "123e4567-dead-beef-a456-426614174000"] as IdentityClaimsDictionary
        var documentBuilder = ModelBasedGraphQLDocumentBuilder(modelSchema: modelType.schema,
                                                               operationType: .subscription)
        documentBuilder.add(decorator: DirectiveNameDecorator(type: .onCreate))
        documentBuilder.add(decorator: ConflictResolutionDecorator())
        documentBuilder.add(decorator: AuthRuleDecorator(.subscription(.onCreate, claims)))
        let document = documentBuilder.build()
        let documentStringValue = """
    subscription OnCreateScenarioATest6Post($owner: String!) {
      onCreateScenarioATest6Post(owner: $owner) {
        id
        title
        __typename
        _version
        _deleted
        _lastChangedAt
        owner
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
        XCTAssertEqual(input, "123e4567-dead-beef-a456-426614174000")
    }

    func testOnUpdateSubscriptionGraphQLRequestCustomIdentityClaim() throws {
        let modelType = ScenarioATest6Post.self as Model.Type
        let claims = ["username": "user1",
                      "sub": "123e4567-dead-beef-a456-426614174000"] as IdentityClaimsDictionary
        var documentBuilder = ModelBasedGraphQLDocumentBuilder(modelType: modelType, operationType: .subscription)
        documentBuilder.add(decorator: DirectiveNameDecorator(type: .onUpdate))
        documentBuilder.add(decorator: ConflictResolutionDecorator())
        documentBuilder.add(decorator: AuthRuleDecorator(.subscription(.onUpdate, claims)))
        let document = documentBuilder.build()
        let documentStringValue = """
    subscription OnUpdateScenarioATest6Post($owner: String!) {
      onUpdateScenarioATest6Post(owner: $owner) {
        id
        title
        __typename
        _version
        _deleted
        _lastChangedAt
        owner
      }
    }
    """
        let request = GraphQLRequest<MutationSyncResult>.subscription(to: modelType.schema,
                                                                      subscriptionType: .onUpdate,
                                                                      claims: claims)

        XCTAssertEqual(document.stringValue, request.document)
        XCTAssertEqual(documentStringValue, request.document)
        XCTAssert(request.responseType == MutationSyncResult.self)
        guard let variables = document.variables else {
            XCTFail("The document doesn't contain variables")
            return
        }
        XCTAssertEqual(variables["owner"] as? String, "123e4567-dead-beef-a456-426614174000")
    }

    func testOnDeleteSubscriptionGraphQLRequestCustomIdentityClaim() throws {
        let modelType = ScenarioATest6Post.self as Model.Type
        let claims = ["username": "user1",
                      "sub": "123e4567-dead-beef-a456-426614174000"] as IdentityClaimsDictionary
        var documentBuilder = ModelBasedGraphQLDocumentBuilder(modelType: modelType, operationType: .subscription)
        documentBuilder.add(decorator: DirectiveNameDecorator(type: .onDelete))
        documentBuilder.add(decorator: ConflictResolutionDecorator())
        documentBuilder.add(decorator: AuthRuleDecorator(.subscription(.onDelete, claims)))
        let document = documentBuilder.build()
        let documentStringValue = """
    subscription OnDeleteScenarioATest6Post($owner: String!) {
      onDeleteScenarioATest6Post(owner: $owner) {
        id
        title
        __typename
        _version
        _deleted
        _lastChangedAt
        owner
      }
    }
    """
        let request = GraphQLRequest<MutationSyncResult>.subscription(to: modelType.schema,
                                                                      subscriptionType: .onDelete,
                                                                      claims: claims)

        XCTAssertEqual(document.stringValue, request.document)
        XCTAssertEqual(documentStringValue, request.document)
        XCTAssert(request.responseType == MutationSyncResult.self)
        guard let variables = document.variables else {
            XCTFail("The document doesn't contain variables")
            return
        }
        XCTAssertEqual(variables["owner"] as? String, "123e4567-dead-beef-a456-426614174000")
    }
}
