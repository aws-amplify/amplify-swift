//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest

@testable import Amplify
@testable import AWSPluginsCore

// MARK: - Multi-field foreign-key `hasOne`

private struct MFKTeam: Model {
    let id: String
    let region: String
    init(id: String = UUID().uuidString, region: String = "na") {
        self.id = id
        self.region = region
    }
    enum CodingKeys: String, ModelKey { case id, region }
    static let keys = CodingKeys.self
    static let schema = defineSchema { model in
        let team = MFKTeam.keys
        model.attributes(.primaryKey(fields: [team.id, team.region]))
        model.fields(
            .field(team.id, is: .required, ofType: .string),
            .field(team.region, is: .required, ofType: .string)
        )
    }

    class Path: ModelPath<MFKTeam> {}
    static var rootPath: PropertyContainerPath? { Path() }
}

private struct MFKProject: Model {
    let id: String
    var teamId: String
    var teamName: String
    var team: MFKTeam?
    init(id: String = UUID().uuidString, teamId: String, teamName: String, team: MFKTeam? = nil) {
        self.id = id
        self.teamId = teamId
        self.teamName = teamName
        self.team = team
    }
    enum CodingKeys: String, ModelKey { case id, teamId, teamName, team }
    static let keys = CodingKeys.self
    static let schema = defineSchema { model in
        let project = MFKProject.keys
        model.fields(
            .id(),
            .field(project.teamId, is: .required, ofType: .string),
            .field(project.teamName, is: .required, ofType: .string),
            .hasOne(project.team, is: .optional, ofType: MFKTeam.self, associatedFields: [MFKTeam.keys.id, MFKTeam.keys.region], targetNames: ["teamId", "teamName"])
        )
    }

    class Path: ModelPath<MFKProject> {
        var team: ModelPath<MFKTeam> { MFKTeam.Path(name: "team", parent: self) }
    }
    static var rootPath: PropertyContainerPath? { Path() }
}

// MARK: - `hasOne` whose foreign key is part of a composite primary key (the issue's `Like.user` shape)

private struct CPKUser: Model {
    let id: String
    init(id: String = UUID().uuidString) { self.id = id }
    enum CodingKeys: String, ModelKey { case id }
    static let keys = CodingKeys.self
    static let schema = defineSchema { model in model.fields(.id()) }
}

private struct CPKLike: Model {
    let id: String
    var userId: String
    var user: CPKUser?
    init(id: String = UUID().uuidString, userId: String, user: CPKUser? = nil) {
        self.id = id
        self.userId = userId
        self.user = user
    }
    enum CodingKeys: String, ModelKey { case id, userId, user }
    static let keys = CodingKeys.self
    static let schema = defineSchema { model in
        let like = CPKLike.keys
        model.fields(
            .id(),
            .field(like.userId, is: .required, ofType: .string),
            .hasOne(like.user, is: .optional, ofType: CPKUser.self, associatedWith: CPKUser.keys.id, targetName: "userId")
        )
        model.attributes(.primaryKey(fields: [like.id, like.userId]))
    }
}

// belongsTo variant: used to verify a non-`hasOne` association is not stripped on mutations.
private struct BTChild: Model {
    let id: String
    init(id: String = UUID().uuidString) { self.id = id }
    enum CodingKeys: String, ModelKey { case id }
    static let keys = CodingKeys.self
    static let schema = defineSchema { model in model.fields(.id()) }

    class Path: ModelPath<BTChild> {}
    static var rootPath: PropertyContainerPath? { Path() }
}

private struct BTParent: Model {
    let id: String
    var parentId: String
    var parent: BTChild?
    init(id: String = UUID().uuidString, parentId: String, parent: BTChild? = nil) {
        self.id = id
        self.parentId = parentId
        self.parent = parent
    }
    enum CodingKeys: String, ModelKey { case id, parentId, parent }
    static let keys = CodingKeys.self
    static let schema = defineSchema { model in
        let btParent = BTParent.keys
        model.fields(
            .id(),
            .field(btParent.parentId, is: .required, ofType: .string),
            .belongsTo(btParent.parent, is: .optional, ofType: BTChild.self, targetName: "parentId")
        )
    }

    class Path: ModelPath<BTParent> {
        var parent: ModelPath<BTChild> { BTChild.Path(name: "parent", parent: self) }
    }
    static var rootPath: PropertyContainerPath? { Path() }
}

class HasOneMutationSelectionEdgeTests: XCTestCase {

    override func setUp() {
        ModelRegistry.register(modelType: MFKProject.self)
        ModelRegistry.register(modelType: MFKTeam.self)
        ModelRegistry.register(modelType: CPKUser.self)
        ModelRegistry.register(modelType: CPKLike.self)
        ModelRegistry.register(modelType: BTParent.self)
        ModelRegistry.register(modelType: BTChild.self)
    }

    override func tearDown() {
        ModelRegistry.reset()
    }

    /// - Given: a `hasOne` backed by a multi-field foreign key (`targetNames: ["teamId","teamName"]`).
    /// - When: an API `.create` mutation is generated.
    /// - Then: the nested object is omitted and BOTH scalar foreign-key fields are selected.
    func testMultiFieldForeignKeyHasOne_apiMutationOmitsNestedAndKeepsAllForeignKeys() {
        let project = MFKProject(teamId: "t-id", teamName: "t-name")
        let doc = GraphQLRequest<MFKProject>.create(project).document

        XCTAssertFalse(doc.contains("team {"), doc)
        XCTAssertTrue(doc.contains("teamId"), doc)
        XCTAssertTrue(doc.contains("teamName"), doc)
    }

    /// - Given: a `hasOne` whose foreign key (`userId`) is also a sort field of the composite
    ///   primary key — the same shape as the issue's `Like.user`.
    /// - When: an API `.create` mutation is generated.
    /// - Then: the nested object is omitted, and the foreign key is still selected exactly once.
    func testCompositeKeyForeignKeyHasOne_apiMutationOmitsNestedAndKeepsForeignKeyOnce() {
        let like = CPKLike(userId: "u-id")
        let doc = GraphQLRequest<CPKLike>.create(like).document

        XCTAssertFalse(doc.contains("user {"), doc)
        // FK present, and not duplicated (it is already a selected primary-key scalar).
        let occurrences = doc.components(separatedBy: "userId").count - 1
        XCTAssertGreaterThanOrEqual(occurrences, 1, doc)
        XCTAssertEqual(doc.components(separatedBy: "\n").count(where: { $0.contains("userId") }), 1, "userId should be selected on exactly one line\n\(doc)")
    }

    /// - Given: an API `.create` mutation that explicitly `includes` a `hasOne` association.
    /// - When: the request document is generated.
    /// - Then: the nested object is still omitted (the hasOne include is dropped, since AppSync
    ///   redacts it to null on a mutation response) while the scalar foreign keys remain.
    func testHasOneIncludeOnApiMutationIsDroppedAndNestedObjectStaysOmitted() {
        let project = MFKProject(teamId: "t-id", teamName: "t-name")
        let doc = GraphQLRequest<MFKProject>.create(project) { path in
            (path as? MFKProject.Path).map { [$0.team] } ?? []
        }.document

        XCTAssertFalse(doc.contains("team {"), doc)
        XCTAssertTrue(doc.contains("teamId"), doc)
        XCTAssertTrue(doc.contains("teamName"), doc)
    }

    /// - Given: an API `.create` mutation that explicitly `includes` a `belongsTo` association.
    /// - When: the request document is generated.
    /// - Then: the nested object is kept — only `hasOne` includes are dropped on mutations.
    func testBelongsToIncludeOnApiMutationIsKept() {
        let btParent = BTParent(parentId: "p-id")
        let doc = GraphQLRequest<BTParent>.create(btParent) { path in
            (path as? BTParent.Path).map { [$0.parent] } ?? []
        }.document

        XCTAssertTrue(doc.contains("parent {"), doc)
    }

    /// Verifies `_associationTargetNames` returns the foreign key(s) for a `belongsTo` and an
    /// empty array for a non-association field.
    func testAssociationTargetNamesForBelongsToAndScalar() {
        XCTAssertEqual(BTParent.schema.field(withName: "parent")?._associationTargetNames, ["parentId"])
        XCTAssertEqual(BTParent.schema.field(withName: "parentId")?._associationTargetNames, [])
    }
}
