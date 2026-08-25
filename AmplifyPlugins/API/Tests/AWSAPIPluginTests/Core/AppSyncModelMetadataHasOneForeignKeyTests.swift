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

class HasOneForeignKeyMetadataTests: XCTestCase {

    override func setUp() {
        ModelRegistry.register(modelType: HasOneFKParent.self)
        ModelRegistry.register(modelType: HasOneFKChild.self)
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
}
