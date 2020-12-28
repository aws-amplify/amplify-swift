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

    override func setUp() {
        Amplify.reset()
        ModelRegistry.register(modelType: Post4.self)
        ModelListDecoderRegistry.registerDecoder(AppSyncList<AnyModel>.self)
        do {
            let configWithAPI = try setUpAPICategory()
            try Amplify.configure(configWithAPI)
        } catch {
            XCTFail(String(describing: "Unable to setup API category for unit tests"))
        }
    }

    func testAppSyncListFromArrayLiteralToJSON() throws {
        let list = AppSyncList(arrayLiteral:
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

    func testAppSyncListDecodeFromGraphQLResponse() throws {
        let graphQLData: JSONValue = [
            "items": [[
                "id": "1",
                "title": JSONValue.init(stringLiteral: "title")
            ], [
                "id": "2",
                "title": JSONValue.init(stringLiteral: "title")
            ]],
            "nextToken": "nextToken"
        ]
        XCTAssertTrue(AppSyncList<Post4>.shouldDecode(json: graphQLData))
        let data = try AppSyncListTests.encode(json: graphQLData)
        var list = try AppSyncListTests.decodeToList(data, responseType: Post4.self)
        guard let appsyncList = list as? AppSyncList else {
            XCTFail("Could not cast to AppSyncList")
            return
        }
        XCTAssertEqual(appsyncList.count, 2)
        list = try AppSyncListTests.decodeToAppSyncList(data, responseType: Post4.self)
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

    func testAppSyncListDecodeToEmptyListSuccess() throws {
        let graphQLData: JSONValue = ""
        XCTAssertFalse(AppSyncList<Post4>.shouldDecode(json: graphQLData))
        let serializedData = try AppSyncListTests.encode(json: graphQLData)
        let list = try AppSyncListTests.decodeToAppSyncList(serializedData, responseType: Post.self)
        XCTAssertNotNil(list)
    }

    private static func encode(json: JSONValue) throws -> Data {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = ModelDateFormatting.encodingStrategy
        return try encoder.encode(json)
    }

    private static func decodeToAppSyncList<R: Decodable>(_ data: Data, responseType: R.Type) throws -> List<R> {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = ModelDateFormatting.decodingStrategy
        return try decoder.decode(AppSyncList<R>.self, from: data)
    }

    private static func decodeToList<R: Decodable>(_ data: Data, responseType: R.Type) throws -> List<R> {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = ModelDateFormatting.decodingStrategy
        return try decoder.decode(List<R>.self, from: data)
    }

    private func setUpAPICategory() throws -> AmplifyConfiguration {
        let apiPlugin = MockAPICategoryPlugin()
        apiPlugin.responders[.queryRequestListener] = QueryRequestListenerResponder<AppSyncList<Post>> { _, listener in
            let list = AppSyncList<Post>()
            let event: GraphQLOperation<AppSyncList<Post>>.OperationResult = .success(.success(list))
            listener?(event)
            return nil
        }
        try Amplify.add(plugin: apiPlugin)

        let apiConfig = APICategoryConfiguration(plugins: [
            "MockAPICategoryPlugin": true
        ])
        let amplifyConfig = AmplifyConfiguration(api: apiConfig)
        return amplifyConfig
    }
}
