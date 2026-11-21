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

class GraphQLHasOneMutationSelectionTests: XCTestCase {

    override func setUp() {
        ModelRegistry.register(modelType: Project2V2.self)
        ModelRegistry.register(modelType: Team2V2.self)
    }

    override func tearDown() {
        ModelRegistry.reset()
    }

    /// - Given: a `Project2V2` whose `team` is a `hasOne` with its foreign key (`teamID`) on the
    ///   source model — the shape from the issue (`Like.user`).
    /// - When: an API category `.create` mutation request is generated.
    /// - Then: the nested `team { ... }` object is NOT selected (AppSync returns it null on a
    ///   mutation response, which caused "Cannot return null for non-nullable type"), while the
    ///   scalar foreign key `teamID` IS selected so the association stays lazy-loadable.
    ///   https://github.com/aws-amplify/amplify-swift/issues/3913
    func testApiCreateMutationForHasOneOmitsNestedObjectAndKeepsForeignKey() {
        let project = Project2V2(name: "name", teamID: "team-id")
        let request = GraphQLRequest<Project2V2>.create(project)

        XCTAssertFalse(request.document.contains("team {"), request.document)
        XCTAssertTrue(request.document.contains("teamID"), request.document)
    }

    /// The same omission applies to API `update` and `delete` (all mutation types share the selection).
    func testApiUpdateAndDeleteMutationsForHasOneOmitNestedObjectAndKeepForeignKey() {
        let project = Project2V2(name: "name", teamID: "team-id")
        let requests: [GraphQLRequest<Project2V2>] = [.update(project), .delete(project)]
        for request in requests {
            XCTAssertFalse(request.document.contains("team {"), request.document)
            XCTAssertTrue(request.document.contains("teamID"), request.document)
        }
    }

    /// - Given: the same `hasOne` model.
    /// - When: a DataStore sync mutation request is generated (`createMutation`).
    /// - Then: the nested `team { ... }` object is STILL selected — the omission is scoped to the
    ///   API category, so DataStore's sync/lazy-load selection is unchanged.
    func testDataStoreSyncMutationForHasOneKeepsNestedObject() {
        let project = Project2V2(name: "name", teamID: "team-id")
        let request = GraphQLRequest<MutationSyncResult>.createMutation(
            of: project,
            modelSchema: Project2V2.schema,
            version: 1
        )

        XCTAssertTrue(request.document.contains("team {"), request.document)
    }

    /// - Given: the same `hasOne` model.
    /// - When: a `.query` document is generated.
    /// - Then: queries are unaffected — the nested `team { ... }` object is still selected.
    func testGetQueryForHasOneStillSelectsNestedObject() {
        var documentBuilder = ModelBasedGraphQLDocumentBuilder(
            modelSchema: Project2V2.schema,
            operationType: .query,
            primaryKeysOnly: true
        )
        documentBuilder.add(decorator: DirectiveNameDecorator(type: .get))
        let document = documentBuilder.build()

        XCTAssertTrue(document.stringValue.contains("team {"), document.stringValue)
    }

    /// - Given: the same `hasOne` model.
    /// - When: a `GraphQLMutation` is built through its public initializers.
    /// - Then: the nested `team { ... }` object is selected (the public inits default to including
    ///   `hasOne` associations; only the API-category path opts out).
    func testGraphQLMutationPublicInitsIncludeNestedHasOne() {
        XCTAssertTrue(
            GraphQLMutation(modelSchema: Project2V2.schema, primaryKeysOnly: true).stringValue.contains("team {")
        )
        XCTAssertTrue(
            GraphQLMutation(modelType: Project2V2.self, primaryKeysOnly: true).stringValue.contains("team {")
        )
    }
}
