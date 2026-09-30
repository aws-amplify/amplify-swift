//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest

@testable import Amplify
@testable import AWSAPIPlugin

// Minimal lazy models: a `hasOne` whose foreign key (`childId`) is on the source model — the same
// shape as the issue's `Like.user`. Both declare `rootPath` so lazy loading applies.
private struct HasOneFKChild: Model {
    let id: String
    init(id: String = UUID().uuidString) { self.id = id }

    enum CodingKeys: String, ModelKey { case id }
    static let keys = CodingKeys.self

    static let schema = defineSchema { model in
        model.fields(.id())
    }

    class Path: ModelPath<HasOneFKChild> {}
    static var rootPath: PropertyContainerPath? { Path() }
}

private struct HasOneFKParent: Model {
    let id: String
    var childId: String
    var child: HasOneFKChild?

    init(id: String = UUID().uuidString, childId: String, child: HasOneFKChild? = nil) {
        self.id = id
        self.childId = childId
        self.child = child
    }

    enum CodingKeys: String, ModelKey {
        case id
        case childId
        case child
    }
    static let keys = CodingKeys.self

    static let schema = defineSchema { model in
        let parent = HasOneFKParent.keys
        model.fields(
            .id(),
            .field(parent.childId, is: .required, ofType: .string),
            .hasOne(
                parent.child,
                is: .optional,
                ofType: HasOneFKChild.self,
                associatedWith: HasOneFKChild.keys.id,
                targetName: "childId"
            )
        )
    }

    class Path: ModelPath<HasOneFKParent> {}
    static var rootPath: PropertyContainerPath? { Path() }
}

// Composite-key variant: the `hasOne` target has a two-field primary key, so the association is
// backed by two foreign keys (`teamId` + `area`). Exercises the multi-identifier rebuild path.
private struct CompositeFKChild: Model {
    let teamId: String
    let area: String
    init(teamId: String = UUID().uuidString, area: String) {
        self.teamId = teamId
        self.area = area
    }

    enum CodingKeys: String, ModelKey {
        case teamId
        case area
    }
    static let keys = CodingKeys.self

    static let schema = defineSchema { model in
        let child = CompositeFKChild.keys
        model.attributes(.primaryKey(fields: [child.teamId, child.area]))
        model.fields(
            .field(child.teamId, is: .required, ofType: .string),
            .field(child.area, is: .required, ofType: .string)
        )
    }

    class Path: ModelPath<CompositeFKChild> {}
    static var rootPath: PropertyContainerPath? { Path() }
}

private struct CompositeFKParent: Model {
    let id: String
    var childTeamId: String
    var childArea: String
    var child: CompositeFKChild?

    init(id: String = UUID().uuidString, childTeamId: String, childArea: String, child: CompositeFKChild? = nil) {
        self.id = id
        self.childTeamId = childTeamId
        self.childArea = childArea
        self.child = child
    }

    enum CodingKeys: String, ModelKey {
        case id
        case childTeamId
        case childArea
        case child
    }
    static let keys = CodingKeys.self

    static let schema = defineSchema { model in
        let parent = CompositeFKParent.keys
        model.fields(
            .id(),
            .field(parent.childTeamId, is: .required, ofType: .string),
            .field(parent.childArea, is: .required, ofType: .string),
            .hasOne(
                parent.child,
                is: .optional,
                ofType: CompositeFKChild.self,
                associatedFields: [CompositeFKChild.keys.teamId, CompositeFKChild.keys.area],
                targetNames: ["childTeamId", "childArea"]
            )
        )
    }

    class Path: ModelPath<CompositeFKParent> {}
    static var rootPath: PropertyContainerPath? { Path() }
}

// Eager (pre-lazy) variant: the associated model declares no `rootPath`, so no lazy rebuild applies.
private struct EagerFKChild: Model {
    let id: String
    init(id: String = UUID().uuidString) { self.id = id }

    enum CodingKeys: String, ModelKey { case id }
    static let keys = CodingKeys.self

    static let schema = defineSchema { model in
        model.fields(.id())
    }
}

private struct EagerFKParent: Model {
    let id: String
    var childId: String
    var child: EagerFKChild?

    init(id: String = UUID().uuidString, childId: String, child: EagerFKChild? = nil) {
        self.id = id
        self.childId = childId
        self.child = child
    }

    enum CodingKeys: String, ModelKey {
        case id
        case childId
        case child
    }
    static let keys = CodingKeys.self

    static let schema = defineSchema { model in
        let parent = EagerFKParent.keys
        model.fields(
            .id(),
            .field(parent.childId, is: .required, ofType: .string),
            .hasOne(
                parent.child,
                is: .optional,
                ofType: EagerFKChild.self,
                associatedWith: EagerFKChild.keys.id,
                targetName: "childId"
            )
        )
    }
}

// Mismatch: a `hasOne` with a single foreign key pointing at a two-field composite-PK child, so the
// rebuild's key count doesn't line up and no metadata is produced.
private struct MismatchParent: Model {
    let id: String
    var childTeamId: String
    var child: CompositeFKChild?

    init(id: String = UUID().uuidString, childTeamId: String, child: CompositeFKChild? = nil) {
        self.id = id
        self.childTeamId = childTeamId
        self.child = child
    }

    enum CodingKeys: String, ModelKey {
        case id
        case childTeamId
        case child
    }
    static let keys = CodingKeys.self

    static let schema = defineSchema { model in
        let parent = MismatchParent.keys
        model.fields(
            .id(),
            .field(parent.childTeamId, is: .required, ofType: .string),
            .hasOne(
                parent.child,
                is: .optional,
                ofType: CompositeFKChild.self,
                associatedWith: CompositeFKChild.keys.teamId,
                targetName: "childTeamId"
            )
        )
    }

    class Path: ModelPath<MismatchParent> {}
    static var rootPath: PropertyContainerPath? { Path() }
}

class HasOneForeignKeyMetadataTests: XCTestCase {

    override func setUp() {
        ModelRegistry.register(modelType: HasOneFKParent.self)
        ModelRegistry.register(modelType: HasOneFKChild.self)
        ModelRegistry.register(modelType: CompositeFKParent.self)
        ModelRegistry.register(modelType: CompositeFKChild.self)
        ModelRegistry.register(modelType: EagerFKParent.self)
        ModelRegistry.register(modelType: EagerFKChild.self)
        ModelRegistry.register(modelType: MismatchParent.self)
    }

    override func tearDown() {
        ModelRegistry.reset()
    }

    /// - Given: a mutation response for a model with a `hasOne` whose foreign key is on the source,
    ///   where the nested object is absent and only the scalar foreign key is present.
    /// - When: `addMetadata` processes the response.
    /// - Then: lazy-load identifier metadata is injected for the association, built from the
    ///   foreign key, so the `hasOne` can still be lazy-loaded.
    ///   Refs https://github.com/aws-amplify/amplify-swift/issues/3913
    func testAddMetadata_hasOneMissingNestedObject_rebuildsLazyIdentifierFromForeignKey() {
        let json: JSONValue = [
            "id": "parent1",
            "childId": "child1",
            "__typename": "HasOneFKParent"
        ]

        let result = AppSyncModelMetadataUtils.addMetadata(
            toModel: json,
            apiName: "apiName",
            authMode: .amazonCognitoUserPools
        )

        guard case .object(let childMetadata) = result["child"],
              case .array(let identifiers) = childMetadata["identifiers"],
              case .object(let identifier) = identifiers.first,
              case .string(let name) = identifier["name"],
              case .string(let value) = identifier["value"] else {
            XCTFail("Expected lazy-load identifier metadata for `child`, rebuilt from the foreign key")
            return
        }
        XCTAssertEqual(name, "id")
        XCTAssertEqual(value, "child1")
    }

    /// - Given: the scalar foreign key is missing from the response.
    /// - When: `addMetadata` processes the response.
    /// - Then: no association metadata is injected (nothing to rebuild from).
    func testAddMetadata_hasOneMissingForeignKey_doesNotInjectMetadata() {
        let json: JSONValue = [
            "id": "parent1",
            "__typename": "HasOneFKParent"
        ]

        let result = AppSyncModelMetadataUtils.addMetadata(
            toModel: json,
            apiName: "apiName",
            authMode: .amazonCognitoUserPools
        )

        if case .object(let object) = result {
            XCTAssertNil(object["child"])
        } else {
            XCTFail("Expected an object result")
        }
    }

    /// - Given: a mutation response for a `hasOne` whose target has a composite (two-field) primary
    ///   key, where the nested object is absent and both scalar foreign keys are present.
    /// - When: `addMetadata` processes the response.
    /// - Then: lazy-load metadata is rebuilt with BOTH identifiers, each mapping the target's
    ///   primary-key field name to the corresponding foreign-key value.
    func testAddMetadata_compositeKeyHasOneMissingNestedObject_rebuildsAllIdentifiers() {
        let json: JSONValue = [
            "id": "parent1",
            "childTeamId": "team-1",
            "childArea": "emea",
            "__typename": "CompositeFKParent"
        ]

        let result = AppSyncModelMetadataUtils.addMetadata(
            toModel: json,
            apiName: "apiName",
            authMode: .amazonCognitoUserPools
        )

        guard case .object(let childMetadata) = result["child"],
              case .array(let identifiers) = childMetadata["identifiers"] else {
            XCTFail("Expected lazy-load identifier metadata for `child`, rebuilt from the foreign keys")
            return
        }

        XCTAssertEqual(identifiers.count, 2)

        func pair(_ value: JSONValue) -> (String, String)? {
            guard case .object(let identifier) = value,
                  case .string(let name) = identifier["name"],
                  case .string(let val) = identifier["value"] else {
                return nil
            }
            return (name, val)
        }
        let pairs = identifiers.compactMap(pair)
        XCTAssertTrue(pairs.contains(where: { $0 == ("teamId", "team-1") }), "\(pairs)")
        XCTAssertTrue(pairs.contains(where: { $0 == ("area", "emea") }), "\(pairs)")
    }

    /// - Given: an eager `hasOne` (associated model has no `rootPath`) whose nested object is absent
    ///   but the foreign key is present.
    /// - When: `addMetadata` processes the response.
    /// - Then: no lazy-reference metadata is injected (eager models can't lazy-load), so the
    ///   association decodes as `nil`. This matches amplify-android/js, where relation loading is
    ///   unsupported on mutations; the related data must be re-queried.
    func testAddMetadata_eagerHasOneMissingNestedObject_doesNotRebuild() {
        let json: JSONValue = [
            "id": "parent1",
            "childId": "child1",
            "__typename": "EagerFKParent"
        ]

        let result = AppSyncModelMetadataUtils.addMetadata(
            toModel: json,
            apiName: "apiName",
            authMode: .amazonCognitoUserPools
        )

        if case .object(let object) = result {
            XCTAssertNil(object["child"])
        } else {
            XCTFail("Expected an object result")
        }
    }

    /// - Given: a `hasOne` whose single foreign key doesn't match the composite-PK child's key count.
    /// - When: `addMetadata` processes the response.
    /// - Then: no metadata is injected (the key counts don't line up), so the association stays nil.
    func testAddMetadata_hasOneForeignKeyCountMismatch_doesNotRebuild() {
        let json: JSONValue = [
            "id": "parent1",
            "childTeamId": "team-1",
            "__typename": "MismatchParent"
        ]

        let result = AppSyncModelMetadataUtils.addMetadata(
            toModel: json,
            apiName: "apiName",
            authMode: .amazonCognitoUserPools
        )

        if case .object(let object) = result {
            XCTAssertNil(object["child"])
        } else {
            XCTFail("Expected an object result")
        }
    }
}
