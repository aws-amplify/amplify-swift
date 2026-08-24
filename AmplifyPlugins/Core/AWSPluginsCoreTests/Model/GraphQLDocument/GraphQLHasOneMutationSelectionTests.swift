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

    /// - Given: a `Project2V2` model whose `team` is a `hasOne` with its foreign key (`teamID`)
    ///   declared on the source model — the same shape as the issue's model (`Like.user`).
    /// - When: a `.create` mutation document is generated.
    /// - Then: the nested `team { ... }` object is NOT selected (on a mutation response AppSync
    ///   returns it as null, which previously caused "Cannot return null for non-nullable type"),
    ///   while the scalar foreign key `teamID` IS selected so the association stays lazy-loadable.
    ///   See https://github.com/aws-amplify/amplify-swift/issues/3913
    func testCreateMutationForHasOneOmitsNestedObjectAndKeepsForeignKey() {
        let project = Project2V2(name: "name", teamID: "team-id")
        var documentBuilder = ModelBasedGraphQLDocumentBuilder(
            modelSchema: Project2V2.schema,
            operationType: .mutation,
            primaryKeysOnly: true
        )
        documentBuilder.add(decorator: DirectiveNameDecorator(type: .create))
        documentBuilder.add(decorator: ModelDecorator(model: project, mutationType: .create))
        let document = documentBuilder.build()

        XCTAssertEqual(document.name, "createProject2V2")
        XCTAssertFalse(document.stringValue.contains("team {"))
        XCTAssertTrue(document.stringValue.contains("teamID"))
    }

    /// The same omission applies to `update` and `delete` (all mutation types share the selection).
    func testUpdateAndDeleteMutationsForHasOneOmitNestedObjectAndKeepForeignKey() {
        let project = Project2V2(name: "name", teamID: "team-id")
        for type in [GraphQLMutationType.update, GraphQLMutationType.delete] {
            var documentBuilder = ModelBasedGraphQLDocumentBuilder(
                modelSchema: Project2V2.schema,
                operationType: .mutation,
                primaryKeysOnly: true
            )
            documentBuilder.add(decorator: DirectiveNameDecorator(type: type))
            documentBuilder.add(decorator: ModelDecorator(model: project, mutationType: type))
            let document = documentBuilder.build()

            XCTAssertFalse(document.stringValue.contains("team {"), "\(type) should not nest the hasOne")
            XCTAssertTrue(document.stringValue.contains("teamID"), "\(type) should keep the scalar FK")
        }
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

        XCTAssertTrue(document.stringValue.contains("team {"))
    }
}
