//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Combine
import XCTest
@testable import AWSPluginsCore

@testable import Amplify
@testable import AmplifyTestCommon
@testable import AWSDataStoreCategoryPlugin

class DataStoreListTests: BaseDataStoreTests {

    func testDataStoreListFromArrayLiteralToJSON() throws {
        let list = DataStoreList(arrayLiteral:
                                    Comment4(id: "id", content: "content"),
                                 Comment4(id: "id", content: "content"))
        XCTAssertNotNil(list)
        XCTAssertEqual(list.count, 2)
        let post = Post4(id: "id", title: "title", comments: list)
        let json = try post.toJSON()
        let expectedJSON = """
        {"id":"id","title":"title","comments":[{"id":"id","content":"content"},{"id":"id","content":"content"}]}
        """
        XCTAssertEqual(json, expectedJSON)
    }

    func testDataStoreListFromJSONPayload() throws {
        let json: JSONValue = [
            [
                "id": "1",
                "title": JSONValue.init(stringLiteral: "title")
            ], [
                "id": "2",
                "title": JSONValue.init(stringLiteral: "title")
            ]
        ]
        XCTAssertTrue(DataStoreList<Post4>.shouldDecode(json: json))
        let data = try DataStoreListTests.encode(json: json)
        var list = try DataStoreListTests.decodeToList(data, responseType: Post4.self)
        guard let dataStoreList = list as? DataStoreList else {
            XCTFail("Could not cast to DataStoreList")
            return
        }
        XCTAssertEqual(dataStoreList.count, 2)
        list = try DataStoreListTests.decodeToDataStoreList(data, responseType: Post4.self)
        XCTAssertNotNil(list)
        XCTAssertEqual(list.count, 2)
        XCTAssertEqual(list.startIndex, 0)
        XCTAssertEqual(list.endIndex, 2)
        XCTAssertEqual(list.index(after: 0), 1)
        XCTAssertEqual(list[0].id, "1")
        for item in list {
            XCTAssertEqual(item.title, "title")
        }
    }

    func testDataStoreListFromAssociationPayload() throws {
        let associatedField = "post"
        let json: JSONValue = [
            "associatedId": "postId123",
            "associatedField": JSONValue.init(stringLiteral: associatedField)
        ]
        let expectedPostField = Comment4.schema.field(withName: associatedField)
        XCTAssertTrue(DataStoreList<Comment4>.shouldDecode(json: json))
        let data = try DataStoreListTests.encode(json: json)
        var list = try DataStoreListTests.decodeToDataStoreList(data, responseType: Comment4.self)
        XCTAssertNotNil(list)
        list = try DataStoreListTests.decodeToList(data, responseType: Comment4.self)
        guard let dataStoreList = list as? DataStoreList else {
            XCTFail("Could not cast to DataStoreList")
            return
        }
        XCTAssertEqual(dataStoreList.count, 0)
        XCTAssertEqual(dataStoreList.associatedId, "postId123")
        XCTAssertEqual(dataStoreList.associatedField?.name, expectedPostField?.name)
    }

    /// - Given: a list a `Post` and a few comments associated with it
    /// - When:
    ///   - the `post.comments` is accessed synchronously
    /// - Then:
    ///   - the list should be correctly loaded and populated
    func testSynchronousLazyLoad() {
        let expect = expectation(description: "a lazy list should return the correct results")

        let postId = preparePostDataForTest()

        Amplify.DataStore.query(Post.self, byId: postId) {
            switch $0 {
            case .success(let result):
                if let post = result, let postComments = post.comments {
                    if let comments = postComments as? DataStoreList<Comment> {
                        XCTAssert(comments.state == .pending)
                        XCTAssertEqual(comments.count, 2)
                        XCTAssertNotNil(comments[0])
                        XCTAssert(comments.state == .loaded)
                    } else {
                        XCTFail("Failed to cast to DataStoreList")
                    }
                } else {
                    XCTFail("Failed to query recently saved post by id")
                }
                expect.fulfill()
            case .failure(let error):
                XCTFail(error.errorDescription)
                expect.fulfill()
            }
        }

        wait(for: [expect], timeout: 1)
    }

    /// - Given: a list a `Post` and a few comments associated with it
    /// - When:
    ///   - the `post.comments` is accessed asynchronously with a callback
    /// - Then:
    ///   - the list should be correctly loaded and populated
    func testAsynchronousLazyLoadWithCallback() {
        let expect = expectation(description: "a lazy list should return the correct results")

        let postId = preparePostDataForTest()

        func checkComments(_ comments: DataStoreList<Comment>) {
            XCTAssert(comments.state == .pending)
            comments.load {
                switch $0 {
                case .success(let loadedComments):
                    XCTAssert(comments.state == .loaded)
                    XCTAssertEqual(loadedComments.count, 2)
                    expect.fulfill()
                case .failure(let error):
                    XCTFail(error.errorDescription)
                    expect.fulfill()
                }
            }
        }

        Amplify.DataStore.query(Post.self, byId: postId) {
            switch $0 {
            case .success(let result):
                if let post = result,
                   let postComments = post.comments,
                   let comments = postComments as? DataStoreList<Comment> {
                    checkComments(comments)
                } else {
                    XCTFail("Failed to query recently saved post by id")
                }
            case .failure(let error):
                XCTFail(error.errorDescription)
                expect.fulfill()
            }
        }

        wait(for: [expect], timeout: 1)
    }

    /// - Given: a list a `Post` and a few comments associated with it
    /// - When:
    ///   - the `post.comments` is accessed asynchronously using the Combine integration
    /// - Then:
    ///   - the list should be correctly loaded and populated through a `Publisher`
    func testAsynchronousLazyLoadWithCombine() {
        let expect = expectation(description: "a lazy list should return the correct results")

        let postId = preparePostDataForTest()

        func checkComments(_ comments: DataStoreList<Comment>) {
            XCTAssert(comments.state == .pending)
            _ = comments.loadAsPublisher().sink(
                receiveCompletion: {
                    switch $0 {
                    case .finished:
                        expect.fulfill()
                    case .failure(let error):
                        XCTFail(error.errorDescription)
                        expect.fulfill()
                    }
                },
                receiveValue: { loadedComments in
                    XCTAssert(comments.state == .loaded)
                    XCTAssertEqual(loadedComments.count, 2)
                }
            )
        }

        Amplify.DataStore.query(Post.self, byId: postId) {
            switch $0 {
            case .success(let result):
                if let post = result,
                   let postComments = post.comments,
                   let comments = postComments as? DataStoreList<Comment> {
                    checkComments(comments)
                } else {
                    XCTFail("Failed to query recently saved post by id")
                }
            case .failure(let error):
                XCTFail(error.errorDescription)
                expect.fulfill()
            }
        }

        wait(for: [expect], timeout: 1)
    }

    // MARK: - Helpers

    func preparePostDataForTest() -> Model.Identifier {
        let post = Post(title: "title", content: "content", createdAt: .now())
        populateData([post])
        populateData([
            Comment(content: "Comment 1", createdAt: .now(), post: post),
            Comment(content: "Comment 2", createdAt: .now(), post: post)
        ])
        return post.id
    }

    private static func encode(json: JSONValue) throws -> Data {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = ModelDateFormatting.encodingStrategy
        return try encoder.encode(json)
    }

    private static func decodeToDataStoreList<R: Decodable>(_ data: Data, responseType: R.Type) throws -> List<R> {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = ModelDateFormatting.decodingStrategy
        return try decoder.decode(DataStoreList<R>.self, from: data)
    }

    private static func decodeToList<R: Decodable>(_ data: Data, responseType: R.Type) throws -> List<R> {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = ModelDateFormatting.decodingStrategy
        return try decoder.decode(List<R>.self, from: data)
    }
}
