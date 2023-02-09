//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Combine
import XCTest

@testable import Amplify
import AWSPluginsCore

extension AWSDataStoreLazyLoadCompositePKTests {

    override func setUp() {
        continueAfterFailure = true
        setUpModelRegistrationOnly(withModels: CompositePKModels())
    }

    /*
     - Given: DataStore is cleared
     - When:
        - Configured with `CompositePKModels`
     - Then:
        - All mutation GraphQL requests on `CompositePKParent` model have correct selection set
        - All subscription GraphQL requests on `CompositePKParent` model have correct selection set
     */
    func testCompositePKParent_withGraphQLOperations_generateCorrectSelectionSets() {
        Operation.allOperations(on: CompositePKParent.schema, model: CompositePKParent.self).forEach { operation in
            let expectedDocument = operation.expectedDocument
            XCTAssertNotNil(expectedDocument)
            XCTAssertEqual(operation.graphQLRequest?.document, expectedDocument)
        }
    }

    /*
     - Given: DataStore is cleared
     - When:
        - Configured with `CompositePKModels`
     - Then:
        - All mutation GraphQL requests on `CompositePKChild` model have correct selection set
        - All subscription GraphQL requests on `CompositePKChild` model have correct selection set
     */
    func testCompositePKChild_withGraphQLOperations_generateCorrectSelectionSets() {
        Operation.allOperations(on: CompositePKChild.schema, model: CompositePKChild.self).forEach { operation in
            let expectedDocument = operation.expectedDocument
            XCTAssertNotNil(expectedDocument)
            XCTAssertEqual(operation.graphQLRequest?.document, expectedDocument)
        }
    }

    /*
     - Given: DataStore is cleared
     - When:
        - Configured with `CompositePKModels`
     - Then:
        - All mutation GraphQL requests on `ChildSansBelongsTo` model have correct selection set
        - All subscription GraphQL requests on `ChildSansBelongsTo` model have correct selection set
     */
    func testChildSansBelongsTo_withGraphQLOperations_generateCorrectSelectionSets() {
        Operation.allOperations(on: ChildSansBelongsTo.schema, model: ChildSansBelongsTo.self).forEach { operation in
            let expectedDocument = operation.expectedDocument
            XCTAssertNotNil(expectedDocument)
            XCTAssertEqual(operation.graphQLRequest?.document, expectedDocument)
        }
    }

    /*
     - Given: DataStore is cleared
     - When:
        - Configured with `CompositePKModels`
     - Then:
        - All mutation GraphQL requests on `ImplicitChild` model have correct selection set
        - All subscription GraphQL requests on `ImplicitChild` model have correct selection set
     */
    func testImplicitChild_withGraphQLOperations_generateCorrectSelectionSets() {
        Operation.allOperations(on: ImplicitChild.schema, model: ImplicitChild.self).forEach { operation in
            let expectedDocument = operation.expectedDocument
            XCTAssertNotNil(expectedDocument)
            XCTAssertEqual(operation.graphQLRequest?.document, expectedDocument)
        }
    }

    /*
     - Given: DataStore is cleared
     - When:
        - Configured with `CompositePKModels`
     - Then:
        - All mutation GraphQL requests on `SrangeExplicitChild` model have correct selection set
        - All subscription GraphQL requests on `SrangeExplicitChild` model have correct selection set
     */
    func testSrangeExplicitChild_withGraphQLOperations_generateCorrectSelectionSets() {
        Operation.allOperations(on: StrangeExplicitChild.schema, model: StrangeExplicitChild.self).forEach { operation in
            let expectedDocument = operation.expectedDocument
            XCTAssertNotNil(expectedDocument)
            XCTAssertEqual(operation.graphQLRequest?.document, expectedDocument)
        }
    }
}


fileprivate enum Operation {
    case mutation(String, ModelSchema, Model.Type)
    case subscription(GraphQLSubscriptionType, ModelSchema, Model.Type)

    static func allOperations(on schema: ModelSchema, model: Model.Type) -> [Operation] {
        allMutationOperations(on: schema, model: model)
        + allSubscriptionOperations(on: schema, model: model)
    }

    static func allMutationOperations(on schema: ModelSchema, model: Model.Type) -> [Operation] {
        [
            Operation.mutation("create", schema, model),
            Operation.mutation("update", schema, model),
            Operation.mutation("delete", schema, model)
        ]
    }

    static func allSubscriptionOperations(on schema: ModelSchema, model: Model.Type) -> [Operation] {
        [
            Operation.subscription(.onUpdate, schema, model),
            Operation.subscription(.onCreate, schema, model),
            Operation.subscription(.onDelete, schema, model)
        ]
    }

    static func mutateGraphQLRequest(
        with operation: String,
        schema: ModelSchema,
        model: Model.Type
    ) -> GraphQLRequest<MutationSyncResult>? {
        let modelInstance = (model as? RandomTestSampleInstance.Type)?.randomInstance()
        switch operation {
        case "create":
            return modelInstance.map {
                GraphQLRequest<MutationSyncResult>.createMutation(of: $0, modelSchema: schema)
            }
        case "update":
            return modelInstance.map {
                GraphQLRequest<MutationSyncResult>.updateMutation(of: $0, modelSchema: schema)
            }
        case "delete":
            return modelInstance.map {
                GraphQLRequest<MutationSyncResult>.deleteMutation(of: $0, modelSchema: schema)
            }
        default: return nil
        }
    }

    var graphQLRequest: GraphQLRequest<MutationSyncResult>? {
        switch self {
        case let .mutation(operation, schema, model):
            return Self.mutateGraphQLRequest(with: operation, schema: schema, model: model)
        case let .subscription(operation, schema, _):
            return GraphQLRequest<MutationSyncResult>.subscription(
                to: schema,
                subscriptionType: operation
            )
        }
    }

    var expectedDocument: String? {
        switch self {
        case let .mutation(operation, _, model):
            return (model as? RandomTestSampleInstance.Type)?.mutationDocument(operation: operation)
        case let .subscription(operation, _, model):
            return (model as? RandomTestSampleInstance.Type)?.subscriptionDocument(operation: operation)
        }
    }
}

fileprivate protocol RandomTestSampleInstance {
    static func randomInstance() -> Model
    static func mutationDocument(operation: String) -> String
    static func subscriptionDocument(operation: GraphQLSubscriptionType) -> String
}

extension CompositePKParent: RandomTestSampleInstance {
    static func subscriptionDocument(operation: GraphQLSubscriptionType) -> String {
        """
        subscription \(operation.rawValue.pascalCased())CompositePKParent {
          \(operation.rawValue.camelCased())CompositePKParent {
            customId
            content
            createdAt
            updatedAt
            __typename
            _version
            _deleted
            _lastChangedAt
          }
        }
        """
    }

    static func mutationDocument(operation: String) -> String {
        """
        mutation \(operation.capitalized)CompositePKParent($input: \(operation.capitalized)CompositePKParentInput!) {
          \(operation.lowercased())CompositePKParent(input: $input) {
            customId
            content
            createdAt
            updatedAt
            __typename
            _version
            _deleted
            _lastChangedAt
          }
        }
        """
    }

    static func randomInstance() -> Model {
        return CompositePKParent(customId: UUID().uuidString, content: UUID().uuidString)
    }
}

extension CompositePKChild: RandomTestSampleInstance {
    static func randomInstance() -> Model {
        return CompositePKChild(childId: UUID().uuidString, content: UUID().uuidString)
    }

    static func mutationDocument(operation: String) -> String {
        """
        mutation \(operation.capitalized)CompositePKChild($input: \(operation.capitalized)CompositePKChildInput!) {
          \(operation.lowercased())CompositePKChild(input: $input) {
            childId
            content
            createdAt
            updatedAt
            parent {
              customId
              content
              createdAt
              updatedAt
              __typename
              _version
              _deleted
              _lastChangedAt
            }
            __typename
            _version
            _deleted
            _lastChangedAt
          }
        }
        """
    }

    static func subscriptionDocument(operation: GraphQLSubscriptionType) -> String {
        """
        subscription \(operation.rawValue.pascalCased())CompositePKChild {
          \(operation.rawValue.camelCased())CompositePKChild {
            childId
            content
            createdAt
            updatedAt
            parent {
              customId
              content
              __typename
              _deleted
            }
            __typename
            _version
            _deleted
            _lastChangedAt
          }
        }
        """
    }

}

extension ChildSansBelongsTo: RandomTestSampleInstance {
    static func randomInstance() -> Model {
        return ChildSansBelongsTo(
            childId: UUID().uuidString,
            content: UUID().uuidString,
            compositePKParentChildrenSansBelongsToCustomId: UUID().uuidString
        )
    }

    static func mutationDocument(operation: String) -> String {
        """
        mutation \(operation.capitalized)ChildSansBelongsTo($input: \(operation.capitalized)ChildSansBelongsToInput!) {
          \(operation.lowercased())ChildSansBelongsTo(input: $input) {
            childId
            content
            compositePKParentChildrenSansBelongsToContent
            compositePKParentChildrenSansBelongsToCustomId
            createdAt
            updatedAt
            __typename
            _version
            _deleted
            _lastChangedAt
          }
        }
        """
    }

    static func subscriptionDocument(operation: GraphQLSubscriptionType) -> String {
        """
        subscription \(operation.rawValue.pascalCased())ChildSansBelongsTo {
          \(operation.rawValue.camelCased())ChildSansBelongsTo {
            childId
            content
            compositePKParentChildrenSansBelongsToContent
            compositePKParentChildrenSansBelongsToCustomId
            createdAt
            updatedAt
            __typename
            _version
            _deleted
            _lastChangedAt
          }
        }
        """
    }
}

extension ImplicitChild: RandomTestSampleInstance {
    static func randomInstance() -> Model {
        let parent = CompositePKParent(customId: UUID().uuidString, content: UUID().uuidString)
        return ImplicitChild(childId: UUID().uuidString, content: UUID().uuidString, parent: parent)
    }

    static func mutationDocument(operation: String) -> String {
        """
        mutation \(operation.capitalized)ImplicitChild($input: \(operation.capitalized)ImplicitChildInput!) {
          \(operation.lowercased())ImplicitChild(input: $input) {
            childId
            content
            createdAt
            updatedAt
            parent {
              customId
              content
              createdAt
              updatedAt
              __typename
              _version
              _deleted
              _lastChangedAt
            }
            __typename
            _version
            _deleted
            _lastChangedAt
          }
        }
        """
    }

    static func subscriptionDocument(operation: GraphQLSubscriptionType) -> String {
        """
        subscription \(operation.rawValue.pascalCased())ImplicitChild {
          \(operation.rawValue.camelCased())ImplicitChild {
            childId
            content
            createdAt
            updatedAt
            parent {
              customId
              content
              __typename
              _deleted
            }
            __typename
            _version
            _deleted
            _lastChangedAt
          }
        }
        """
    }
}

extension StrangeExplicitChild: RandomTestSampleInstance {
    static func randomInstance() -> Model {
        let parent = CompositePKParent(customId: UUID().uuidString, content: UUID().uuidString)
        return StrangeExplicitChild(strangeId: UUID().uuidString, content: UUID().uuidString, parent: parent)
    }

    static func mutationDocument(operation: String) -> String {
        """
        mutation \(operation.capitalized)StrangeExplicitChild($input: \(operation.capitalized)StrangeExplicitChildInput!) {
          \(operation.lowercased())StrangeExplicitChild(input: $input) {
            strangeId
            content
            createdAt
            updatedAt
            parent {
              customId
              content
              createdAt
              updatedAt
              __typename
              _version
              _deleted
              _lastChangedAt
            }
            __typename
            _version
            _deleted
            _lastChangedAt
          }
        }
        """
    }

    static func subscriptionDocument(operation: GraphQLSubscriptionType) -> String {
        """
        subscription \(operation.rawValue.pascalCased())StrangeExplicitChild {
          \(operation.rawValue.camelCased())StrangeExplicitChild {
            strangeId
            content
            createdAt
            updatedAt
            parent {
              customId
              content
              __typename
              _deleted
            }
            __typename
            _version
            _deleted
            _lastChangedAt
          }
        }
        """
    }


}
