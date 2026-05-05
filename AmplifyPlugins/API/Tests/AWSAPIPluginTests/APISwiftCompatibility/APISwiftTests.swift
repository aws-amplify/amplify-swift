//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import XCTest

final class APISwiftTests: XCTestCase {

    // MARK: - Enum Decoding Tests

    /// Tests that a non-optional enum field is correctly decoded from a JSON string value
    func testEnumFieldDecoding() throws {
        let jsonString = """
        {"getPost": {"__typename": "Post", "id": "1", "title": "Hello", "status": "PUBLISHED"}}
        """
        let data = jsonString.data(using: .utf8)!
        let decoded = try JSONDecoder().decode(
            GetPostWithStatusQuery.Data.self, from: data
        )
        let post = try XCTUnwrap(decoded.getPost)
        XCTAssertEqual(post.status, PostStatus.published)
        XCTAssertEqual(post.id, "1")
        XCTAssertEqual(post.title, "Hello")
    }

    /// Tests that an optional enum field is correctly decoded from a JSON string value
    func testOptionalEnumFieldDecoding() throws {
        let jsonString = """
        {"getPost": {"__typename": "Post", "id": "2", "title": "World", "status": "DRAFT"}}
        """
        let data = jsonString.data(using: .utf8)!
        let decoded = try JSONDecoder().decode(
            GetPostWithOptionalStatusQuery.Data.self, from: data
        )
        let post = try XCTUnwrap(decoded.getPost)
        XCTAssertEqual(post.status, PostStatus.draft)
    }

    /// Tests that an optional enum field with null value decodes as nil
    func testOptionalEnumFieldDecodingNull() throws {
        let jsonString = """
        {"getPost": {"__typename": "Post", "id": "3", "title": "Null Status", "status": null}}
        """
        let data = jsonString.data(using: .utf8)!
        let decoded = try JSONDecoder().decode(
            GetPostWithOptionalStatusQuery.Data.self, from: data
        )
        let post = try XCTUnwrap(decoded.getPost)
        XCTAssertNil(post.status)
    }

    /// Tests that enum fields inside nested list objects are correctly decoded
    func testEnumFieldInNestedListDecoding() throws {
        let jsonString = """
        {"listPosts": {"__typename": "ModelPostConnection", "items": [{"__typename": "Post", "id": "1", "title": "First", "status": "DRAFT"}, {"__typename": "Post", "id": "2", "title": "Second", "status": "ARCHIVED"}]}}
        """
        let data = jsonString.data(using: .utf8)!
        let decoded = try JSONDecoder().decode(
            ListPostsWithStatusQuery.Data.self, from: data
        )
        let listPosts = try XCTUnwrap(decoded.listPosts)
        let items = try XCTUnwrap(listPosts.items)
        XCTAssertEqual(items.count, 2)
        XCTAssertEqual(items[0].status, PostStatus.draft)
        XCTAssertEqual(items[1].status, PostStatus.archived)
    }

    /// Tests that unknown enum raw values are handled correctly
    func testUnknownEnumValueDecoding() throws {
        let jsonString = """
        {"getPost": {"__typename": "Post", "id": "4", "title": "Unknown", "status": "SOME_NEW_STATUS"}}
        """
        let data = jsonString.data(using: .utf8)!
        let decoded = try JSONDecoder().decode(
            GetPostWithStatusQuery.Data.self, from: data
        )
        let post = try XCTUnwrap(decoded.getPost)
        XCTAssertEqual(post.status, PostStatus.unknown("SOME_NEW_STATUS"))
    }

    // MARK: - Existing Tests

    func testCreateBlogMutation() {
        let file = S3ObjectInput(bucket: "bucket", key: "let", region: "region")
        let input = CreateBlogInput(name: "name", file: file)
        let mutation = CreateBlogMutation(input: input)

        let request = GraphQLRequest<CreateBlogMutation.Data>(
            document: CreateBlogMutation.requestString,
            variables: mutation.variables?.jsonObject,
            responseType: CreateBlogMutation.Data.self
        )

        let expectedDocument = """
        mutation CreateBlog($input: CreateBlogInput!, $condition: ModelBlogConditionInput) {
          createBlog(input: $input, condition: $condition) {
            __typename
            id
            name
            posts {
              __typename
              nextToken
              startedAt
            }
            file {
              __typename
              ...S3Object
            }
            createdAt
            updatedAt
            _version
            _deleted
            _lastChangedAt
          }
        }fragment S3Object on S3Object {
          __typename
          bucket
          key
          region
        }
        """
        XCTAssertEqual(expectedDocument, request.document)
    }

}
