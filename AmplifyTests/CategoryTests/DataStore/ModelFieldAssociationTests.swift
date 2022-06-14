//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
@testable import Amplify
@testable import AmplifyTestCommon

class ModelFieldAssociationTests: XCTestCase {

    override func setUp() async throws {
        ModelRegistry.register(modelType: Post.self)
        ModelRegistry.register(modelType: Comment.self)
    }

    func testBelongsToWithCodingKeys() {
        let belongsTo = ModelAssociation.belongsTo(associatedWith: Comment.keys.post, targetName: "postID")
        guard case .belongsTo(let fieldName, let target) = belongsTo else {
            XCTFail("Should create belongsTo association")
            return
        }
        XCTAssertEqual(fieldName, Comment.keys.post.stringValue)
        XCTAssertEqual(target, "postID")
    }

    func testHasManyWithCodingKeys() {
        let hasMany = ModelAssociation.hasMany(associatedWith: Comment.keys.post)
        guard case .hasMany(let fieldName) = hasMany else {
            XCTFail("Should create hasMany association")
            return
        }
        XCTAssertEqual(fieldName, Comment.keys.post.stringValue)
    }

    func testHasOneWithCodingKeys() {
        let hasOne = ModelAssociation.hasOne(associatedWith: Comment.keys.post)
        guard case .hasOne(let fieldName, let target) = hasOne else {
            XCTFail("Should create hasOne association")
            return
        }
        XCTAssertEqual(fieldName, Comment.keys.post.stringValue)
        XCTAssertNil(target)
    }

    func testHasOneWithCodingKeysWithTargetName() {
        let hasOne = ModelAssociation.hasOne(associatedWith: Comment.keys.post, targetName: "postID")
        guard case .hasOne(let fieldName, let target) = hasOne else {
            XCTFail("Should create hasOne association")
            return
        }
        XCTAssertEqual(fieldName, Comment.keys.post.stringValue)
        XCTAssertEqual(target, "postID")
    }

    func testBelongsToWithTargetName() {
        let belongsTo = ModelAssociation.belongsTo(targetName: "postID")
        guard case .belongsTo(let fieldName, let target) = belongsTo else {
            XCTFail("Should create belongsTo association")
            return
        }
        XCTAssertNil(fieldName)
        XCTAssertNil(target)
    }

    func testModelFieldWithBelongsToAssociation() {
        let belongsTo = ModelAssociation.belongsTo(associatedWith: nil, targetName: "commentPostId")
        let field = ModelField.init(name: "post",
                                    type: .model(type: Post.self),
                                    association: belongsTo)

        XCTAssertEqual("Post", field.associatedModelName)
        XCTAssertTrue(field.hasAssociation)
        XCTAssertTrue(field.isAssociationOwner)
    }

    func testModelFieldWithHasManyAssociation() {
        let hasMany = ModelAssociation.hasMany(associatedWith: Comment.keys.post)
        let field = ModelField.init(name: "comments",
                                    type: .collection(of: Comment.self),
                                    isArray: true,
                                    association: hasMany)

        XCTAssertEqual("Comment", field.associatedModelName)
        XCTAssertTrue(field.hasAssociation)
        XCTAssertFalse(field.isAssociationOwner)
        XCTAssertNotNil(field.associatedField)
    }

    func testModelFieldWithHasOneAssociation() {
        let hasOne = ModelAssociation.hasOne(associatedWith: Comment.keys.post, targetName: "postID")
        let field = ModelField.init(name: "comment",
                                    type: .model(type: Comment.self),
                                    association: hasOne)

        XCTAssertEqual("Comment", field.associatedModelName)
        XCTAssertTrue(field.hasAssociation)
        XCTAssertFalse(field.isAssociationOwner)
        XCTAssertTrue(field.isOneToOne)
        XCTAssertNotNil(field.associatedField)
    }

}
