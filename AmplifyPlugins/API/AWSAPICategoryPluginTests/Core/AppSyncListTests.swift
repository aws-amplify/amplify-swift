//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
@testable import Amplify
@testable import AWSPluginsCore
@testable import AmplifyTestCommon
@testable import AWSAPICategoryPlugin

class AppSyncListTests: XCTestCase {

    var mockAPIPlugin: MockAPICategoryPlugin!

    override func setUp() {
        Amplify.reset()
        ModelRegistry.register(modelType: Post4.self)
        ModelRegistry.register(modelType: Comment4.self)
        ModelListDecoderRegistry.registerDecoder(AppSyncList<AnyModel>.self)
        do {
            let configWithAPI = try setUpAPICategory()
            try Amplify.configure(configWithAPI)
        } catch {
            XCTFail(String(describing: "Unable to setup API category for unit tests"))
        }
    }

    func testAppSyncListDecodeFromGraphQLResponse() throws {
        let graphQLData: JSONValue = [
            "items": [[
                "id": "1",
                "title": JSONValue.init(stringLiteral: "title")
            ], [
                "id": "2",
                "title": JSONValue.init(stringLiteral: "title"),
            ]],
            "nextToken": "nextToken"
        ]
        let data = try AppSyncListTests.encode(json: graphQLData)

        let list = try AppSyncListTests.decode(data, responseType: Post4.self)
        XCTAssertEqual(list.count, 2)
        guard let appSyncList = list as? AppSyncList else {
            XCTFail("Could not cast to AppSyncList")
            return
        }
        XCTAssertNil(appSyncList.associatedId)
        XCTAssertNil(appSyncList.associatedField)
        XCTAssertNil(appSyncList.nextToken)
        XCTAssertNil(appSyncList.document)
        XCTAssertNil(appSyncList.variables)
        XCTAssertEqual(appSyncList.state, .loaded)
    }

    func testAppSyncListDecodeFromAppSyncListPayload() throws {
        let graphQLData: JSONValue = [
            "items": [[
                "id": "1",
                "title": JSONValue.init(stringLiteral: "title"),
                "__typename": "Post4"
            ], [
                "id": "2",
                "title": JSONValue.init(stringLiteral: "title"),
                "__typename": "Post4"
            ]],
            "nextToken": "nextToken"
        ]
        let variables: [String: JSONValue] = [
            "filter": [
                "id": [
                    "eq": "123"
                ]
            ],
            "limit": 1_000
        ]
        let appSyncListPayload = AppSyncListPayload(document: "document",
                                                    variables: variables,
                                                    graphQLData: graphQLData)
        let data = try AppSyncListTests.encode(payload: appSyncListPayload)

        let list = try AppSyncListTests.decode(data, responseType: Post4.self)
        XCTAssertEqual(list.count, 2)
        guard let appSyncList = list as? AppSyncList else {
            XCTFail("Could not cast to AppSyncList")
            return
        }
        XCTAssertNil(appSyncList.associatedId)
        XCTAssertNil(appSyncList.associatedField)
        XCTAssertEqual(appSyncList.nextToken, "nextToken")
        XCTAssertEqual(appSyncList.document, "document")
        XCTAssertNotNil(appSyncList.variables)
        XCTAssertEqual(appSyncList.state, .loaded)
        for post in list {
            let comments = post.comments
            guard let appSyncComments = comments as? AppSyncList else {
                XCTFail("Could not cast to AppSyncList")
                return
            }
            XCTAssertEqual(appSyncComments.associatedId, post.id)
            XCTAssertNotNil(appSyncComments.associatedField)
            XCTAssertEqual(appSyncComments.associatedField!.name, "post")
            XCTAssertNil(appSyncComments.nextToken)
            XCTAssertNil(appSyncComments.document)
            XCTAssertNil(appSyncComments.variables)
            XCTAssertEqual(appSyncComments.state, .pending)
        }
    }

    func testAppSyncListDecodeFromAssociatedDataThenFetch() throws {
        mockAPIPlugin.responders[.queryRequestListener] =
            QueryRequestListenerResponder<AppSyncList<Comment4>> { _, listener in
                let list = AppSyncList<Comment4>()
                list.elements = [Comment4(content: "content", post: Post4(title: "title"))]
                let event: GraphQLOperation<AppSyncList<Comment4>>.OperationResult = .success(.success(list))
                listener?(event)
                return nil
        }

        let associatedData: JSONValue = [
            "associatedId": "postId123",
            "associatedField": "post",
            "listType": "appSyncList"
        ]
        let data = try AppSyncListTests.encode(json: associatedData)
        let list = try AppSyncListTests.decode(data, responseType: Comment4.self)
        guard let appSyncList = list as? AppSyncList else {
            XCTFail("Could not cast to AppSyncList")
            return
        }
        XCTAssertEqual(appSyncList.associatedId, "postId123")
        XCTAssertNotNil(appSyncList.associatedField)
        XCTAssertEqual(appSyncList.associatedField!.name, "post")
        XCTAssertNil(appSyncList.nextToken)
        XCTAssertNil(appSyncList.document)
        XCTAssertNil(appSyncList.variables)
        XCTAssertEqual(appSyncList.state, .pending)
        XCTAssertEqual(appSyncList.elements.count, 0)

        let fetchCompleted = expectation(description: "fetch completed")
        list.fetch { result in
            switch result {
            case .success:
                fetchCompleted.fulfill()
            case .failure(let error):
                XCTFail("\(error)")
            }
        }
        wait(for: [fetchCompleted], timeout: 1)
        XCTAssertEqual(list.count, 1)
        XCTAssertEqual(appSyncList.state, .loaded)
        XCTAssertEqual(appSyncList.elements.count, 1)
    }

    func testAppSyncListFetchFails() throws {
        mockAPIPlugin.responders[.queryRequestListener] =
            QueryRequestListenerResponder<AppSyncList<Comment4>> { _, listener in
                let event: GraphQLOperation<AppSyncList<Comment4>>.OperationResult =
                    .failure(APIError.unknown("", "", nil))
                listener?(event)
                return nil
        }

        let associatedData: JSONValue = [
            "associatedId": "postId123",
            "associatedField": "post",
            "listType": "appSyncList"
        ]
        let data = try AppSyncListTests.encode(json: associatedData)
        let list = try AppSyncListTests.decode(data, responseType: Comment4.self)
        guard let appSyncList = list as? AppSyncList else {
            XCTFail("Could not cast to AppSyncList")
            return
        }
        XCTAssertEqual(appSyncList.state, .pending)
        XCTAssertEqual(appSyncList.elements.count, 0)

        let fetchCompleted = expectation(description: "fetch completed")
        list.fetch { result in
            switch result {
            case .success:
                XCTFail("Should have failed")
            case .failure:
                fetchCompleted.fulfill()
            }
        }
        wait(for: [fetchCompleted], timeout: 1)
        XCTAssertEqual(appSyncList.state, .pending)
        XCTAssertEqual(appSyncList.elements.count, 0)
    }

    func testAppSyncListImplicitFetchOnCount() throws {
        mockAPIPlugin.responders[.queryRequestListener] =
            QueryRequestListenerResponder<AppSyncList<Comment4>> { _, listener in
                let list = AppSyncList<Comment4>()
                list.elements = [Comment4(content: "content", post: Post4(title: "title"))]
                let event: GraphQLOperation<AppSyncList<Comment4>>.OperationResult = .success(.success(list))
                listener?(event)
                return nil
        }

        let associatedData: JSONValue = [
            "associatedId": "postId123",
            "associatedField": "post",
            "listType": "appSyncList"
        ]
        let data = try AppSyncListTests.encode(json: associatedData)
        let list = try AppSyncListTests.decode(data, responseType: Comment4.self)
        guard let appSyncList = list as? AppSyncList else {
            XCTFail("Could not cast to AppSyncList")
            return
        }
        XCTAssertEqual(appSyncList.state, .pending)
        XCTAssertEqual(appSyncList.elements.count, 0)

        if list.count != 1 {
            XCTFail("Implicit fetch failed")
        }

        XCTAssertEqual(appSyncList.state, .loaded)
        XCTAssertEqual(appSyncList.elements.count, 1)
    }

    func testAppSyncListImplicitFetchOnEnumerated() throws {
        mockAPIPlugin.responders[.queryRequestListener] =
            QueryRequestListenerResponder<AppSyncList<Comment4>> { _, listener in
                let list = AppSyncList<Comment4>()
                list.elements = [Comment4(content: "content", post: Post4(title: "title"))]
                let event: GraphQLOperation<AppSyncList<Comment4>>.OperationResult = .success(.success(list))
                listener?(event)
                return nil
        }

        let associatedData: JSONValue = [
            "associatedId": "postId123",
            "associatedField": "post",
            "listType": "appSyncList"
        ]
        let data = try AppSyncListTests.encode(json: associatedData)
        let list = try AppSyncListTests.decode(data, responseType: Comment4.self)
        guard let appSyncList = list as? AppSyncList else {
            XCTFail("Could not cast to AppSyncList")
            return
        }
        XCTAssertEqual(appSyncList.state, .pending)
        XCTAssertEqual(appSyncList.elements.count, 0)
        for (index, comment) in list.enumerated() {
            XCTAssertEqual(index, 0)
            XCTAssertNotNil(comment)
        }
        XCTAssertEqual(appSyncList.state, .loaded)
        XCTAssertEqual(appSyncList.elements.count, 1)
    }

    func testAppSyncListMulitpleFetchReturnsSameResult() throws {
        let apiCalledOnce = expectation(description: "API is called only once for multiple fetch")
        apiCalledOnce.assertForOverFulfill = true
        mockAPIPlugin.responders[.queryRequestListener] =
            QueryRequestListenerResponder<AppSyncList<Comment4>> { _, listener in
                apiCalledOnce.fulfill()
                let list = AppSyncList<Comment4>()
                list.elements = [Comment4(content: "content", post: Post4(title: "title"))]
                let event: GraphQLOperation<AppSyncList<Comment4>>.OperationResult = .success(.success(list))
                listener?(event)
                return nil
            }

        let associatedData: JSONValue = [
            "associatedId": "postId123",
            "associatedField": "post",
            "listType": "appSyncList"
        ]
        let data = try AppSyncListTests.encode(json: associatedData)
        let list = try AppSyncListTests.decode(data, responseType: Comment4.self)
        guard let appSyncList = list as? AppSyncList else {
            XCTFail("Could not cast to AppSyncList")
            return
        }
        XCTAssertEqual(appSyncList.state, .pending)
        XCTAssertEqual(appSyncList.elements.count, 0)
        XCTAssertEqual(list.count, 1)
        XCTAssertEqual(appSyncList.state, .loaded)
        for (index, comment) in list.enumerated() {
            XCTAssertEqual(index, 0)
            XCTAssertNotNil(comment)
        }
        for comment in list {
            XCTAssertNotNil(comment)
        }
        wait(for: [apiCalledOnce], timeout: 1)
    }

    func testAppSyncListImplicitFetchFails() throws {
        mockAPIPlugin.responders[.queryRequestListener] =
            QueryRequestListenerResponder<AppSyncList<Comment4>> { _, listener in
                let event: GraphQLOperation<AppSyncList<Comment4>>.OperationResult =
                    .failure(APIError.unknown("", "", nil))
                listener?(event)
                return nil
        }

        let associatedData: JSONValue = [
            "associatedId": "postId123",
            "associatedField": "post",
            "listType": "appSyncList"
        ]
        let data = try AppSyncListTests.encode(json: associatedData)
        let list = try AppSyncListTests.decode(data, responseType: Comment4.self)
        guard let appSyncList = list as? AppSyncList else {
            XCTFail("Could not cast to AppSyncList")
            return
        }
        XCTAssertEqual(appSyncList.state, .pending)
        XCTAssertEqual(appSyncList.elements.count, 0)
        for (index, comment) in list.enumerated() {
            XCTAssertEqual(index, 0)
            XCTAssertNotNil(comment)
        }
        XCTAssertEqual(appSyncList.state, .pending)
        XCTAssertEqual(list.count, 0)

    }

    func testAppSyncListImplicitFetchOnHasNextPage() throws {
        mockAPIPlugin.responders[.queryRequestListener] =
            QueryRequestListenerResponder<AppSyncList<Comment4>> { _, listener in
                let list = AppSyncList<Comment4>()
                list.elements = [Comment4(content: "content", post: Post4(title: "title"))]
                let event: GraphQLOperation<AppSyncList<Comment4>>.OperationResult = .success(.success(list))
                listener?(event)
                return nil
            }

        let associatedData: JSONValue = [
            "associatedId": "postId123",
            "associatedField": "post",
            "listType": "appSyncList"
        ]
        let data = try AppSyncListTests.encode(json: associatedData)
        let list = try AppSyncListTests.decode(data, responseType: Comment4.self)
        guard let appSyncList = list as? AppSyncList else {
            XCTFail("Could not cast to AppSyncList")
            return
        }
        XCTAssertEqual(appSyncList.state, .pending)
        XCTAssertEqual(appSyncList.elements.count, 0)

        if list.hasNextPage() {
            XCTFail("Implicit fetch completed, however expected single page of results")
        }

        XCTAssertEqual(appSyncList.state, .loaded)
        XCTAssertEqual(list.count, 1)
    }

    func testAppSyncListGetNextPage() throws {
        mockAPIPlugin.responders[.queryRequestListener] =
            QueryRequestListenerResponder<AppSyncList<Comment4>> { _, listener in
                let list = AppSyncList<Comment4>()
                list.nextToken = "nextToken"
                list.elements = [Comment4(id: "commentId",
                                         content: "content",
                                         post: Post4(title: "title"))]
                let event: GraphQLOperation<AppSyncList<Comment4>>.OperationResult = .success(.success(list))
                listener?(event)
                return nil
            }

        let associatedData: JSONValue = [
            "associatedId": "postId123",
            "associatedField": "post",
            "listType": "appSyncList"
        ]
        let data = try AppSyncListTests.encode(json: associatedData)
        let list = try AppSyncListTests.decode(data, responseType: Comment4.self)
        guard let appSyncList = list as? AppSyncList else {
            XCTFail("Could not cast to AppSyncList")
            return
        }
        XCTAssertNil(appSyncList.nextToken)
        XCTAssertEqual(appSyncList.state, .pending)
        XCTAssertEqual(appSyncList.elements.count, 0)

        for comment in list {
            XCTAssertEqual(comment.id, "commentId")
        }
        XCTAssertEqual(appSyncList.state, .loaded)
        XCTAssertEqual(appSyncList.nextToken, "nextToken")
        XCTAssertTrue(list.hasNextPage())
        let getNextPageCompleted = expectation(description: "getNextPage completed")
        list.getNextPage { result in
            switch result {
            case .success(let list):
                XCTAssertNotNil(list)
                getNextPageCompleted.fulfill()
            case .failure(let error):
                XCTFail("\(error)")
            }
        }
        wait(for: [getNextPageCompleted], timeout: 1)
    }


    private static func encode(json: JSONValue) throws -> Data {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = ModelDateFormatting.encodingStrategy
        return try encoder.encode(json)
    }

    private static func encode(payload: AppSyncListPayload) throws -> Data {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = ModelDateFormatting.encodingStrategy
        return try encoder.encode(payload)
    }

    private static func decode<R: Decodable>(_ data: Data, responseType: R.Type) throws -> List<R> {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = ModelDateFormatting.decodingStrategy
        return try decoder.decode(List<R>.self, from: data)
    }

    private func setUpAPICategory() throws -> AmplifyConfiguration {
        mockAPIPlugin = MockAPICategoryPlugin()
        try Amplify.add(plugin: mockAPIPlugin)

        let apiConfig = APICategoryConfiguration(plugins: [
            "MockAPICategoryPlugin": true
        ])
        let amplifyConfig = AmplifyConfiguration(api: apiConfig)
        return amplifyConfig
    }
}
