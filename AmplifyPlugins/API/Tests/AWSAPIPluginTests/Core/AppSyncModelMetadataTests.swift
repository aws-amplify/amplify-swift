//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
import AmplifyTestCommon
@testable import Amplify
@testable import AWSAPIPlugin

class ModelMetadataTests: XCTestCase {
    override func setUp() {
        ModelRegistry.register(modelType: Comment4.self)
        ModelRegistry.register(modelType: Post4.self)
    }

    override class func tearDown() {
        ModelRegistry.reset()
    }

    func testShouldAddMetadataTrue() {
        let model: JSONValue = [
            "id": "id",
            "__typename": "Post4"
        ]
        XCTAssertTrue(AppSyncModelMetadataUtils.shouldAddMetadata(toModel: model))
    }

    func testShouldAddMetadataFalse_MissingTypename() {
        let model: JSONValue = [
            "id": "id"
        ]
        XCTAssertFalse(AppSyncModelMetadataUtils.shouldAddMetadata(toModel: model))
    }

    func testShouldAddMetadataFalse_InvalidTypeName() {
        let model: JSONValue = [
            "__typename": "InvalidName"
        ]
        XCTAssertFalse(AppSyncModelMetadataUtils.shouldAddMetadata(toModel: model))
    }

    func testAddMetadataToModelArraySuccess() {
        let jsonArray: [JSONValue] = [
            [
                "id": "postId",
                "title": JSONValue.init(stringLiteral: "title"),
                "__typename": "Post4"
            ], [
                "id": "postId",
                "title": JSONValue.init(stringLiteral: "title"),
                "__typename": "Post4"
            ]
        ]
        let posts = AppSyncModelMetadataUtils.addMetadata(toModelArray: jsonArray, apiName: "apiName")
        XCTAssertEqual(posts.count, 2)
        for post in posts {
            guard case .object(let associationData) = post["comments"],
                  case .array(let associatedFields) = associationData["appSyncAssociatedFields"],
                  case .array(let associatedIdentifiers) = associationData["appSyncAssociatedIdentifiers"],
                  case .string(let apiName) = associationData["apiName"] else {
                XCTFail("Missing association metadata for comments")
                return
            }
            XCTAssertEqual(associatedIdentifiers[0], "postId")
            XCTAssertEqual(associatedFields, ["post"])
            XCTAssertEqual(apiName, "apiName")
        }
    }

    func testAddMetadataToModelSuccess() {
        let json: JSONValue = [
            "id": "postId",
            "title": JSONValue.init(stringLiteral: "title"),
            "__typename": "Post4"
        ]

        let post = AppSyncModelMetadataUtils.addMetadata(toModel: json, apiName: "apiName")
        guard case .object(let associationData) = post["comments"],
              case .array(let associatedFields) = associationData["appSyncAssociatedFields"],
              case .array(let associatedIdentifiers) = associationData["appSyncAssociatedIdentifiers"],
              case .string(let apiName) = associationData["apiName"] else {
            XCTFail("Missing association metadata for comments")
            return
        }
        XCTAssertEqual(associatedIdentifiers[0], "postId")
        XCTAssertEqual(associatedFields, ["post"])
        XCTAssertEqual(apiName, "apiName")
    }

    func testAddMetadataToModelNoOp_NotAnObject() {
        let json: JSONValue = "notAnObject"
        let result = AppSyncModelMetadataUtils.addMetadata(toModel: json, apiName: "apiName")
        XCTAssertEqual(result, "notAnObject")
    }

    func testAddMetadatToModelNoOp_MissingTypename() {
        let json: JSONValue = [
            "id": "postId",
            "title": JSONValue.init(stringLiteral: "title")
        ]

        let post = AppSyncModelMetadataUtils.addMetadata(toModel: json, apiName: "apiName")
        guard case .object(let postObject) = post,
              case .string = postObject["id"],
              case .string = postObject["title"] else {
            XCTFail("Should have exactly the number of fields in original json object")
            return
        }
        XCTAssertEqual(postObject.count, 2)
    }

    func testAddMetadataToModelNoOp_MissingModelSchema() {
        let json: JSONValue = [
            "id": "postId",
            "title": JSONValue.init(stringLiteral: "title"),
            "__typename": "InvalidModelName"
        ]

        let post = AppSyncModelMetadataUtils.addMetadata(toModel: json, apiName: "apiName")
        guard case .object(let postObject) = post,
              case .string = postObject["id"],
              case .string = postObject["title"],
              case .string = postObject["__typename"] else {
            XCTFail("Should have exactly the number of fields in original json object")
            return
        }
        XCTAssertEqual(postObject.count, 3)
    }

    func testAddMetadataNoOp_MissingId() {
        let json: JSONValue = [
            "title": JSONValue.init(stringLiteral: "title"),
            "__typename": "Post4"
        ]

        let post = AppSyncModelMetadataUtils.addMetadata(toModel: json, apiName: "apiName")
        guard case .object(let postObject) = post,
              case .string = postObject["title"],
              case .string = postObject["__typename"] else {
            XCTFail("Should have exactly the number of fields in original json object")
            return
        }
        XCTAssertEqual(postObject.count, 2)
    }

    func testAddMetadataNoOp_NestedDataAtArrayAssociation() {
        let json: JSONValue = [
            "id": "postId",
            "title": JSONValue.init(stringLiteral: "title"),
            "__typename": "Post4",
            "comments": [
                "items": [
                    ["id": "commentId", "content": "content", "__typename": "Comment4"]
                ],
                "nextToken": "nextToken"
            ]
        ]

        let post = AppSyncModelMetadataUtils.addMetadata(toModel: json, apiName: "apiName")
        guard case .object(let associationData) = post["comments"],
              associationData["appSyncAssociatedField"] == nil,
              associationData["appSyncAssociatedIdentifiers"] == nil,
              associationData["apiName"] == nil else {
            XCTFail("Nested levels of data should not have metadata added")
            return
        }
    }
}
