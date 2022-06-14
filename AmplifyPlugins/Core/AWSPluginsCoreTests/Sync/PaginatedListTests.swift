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

class PaginatedListTests: XCTestCase {

    let syncQueryJSON = """
    {
      "items": [
        {
          "id": "post-id",
          "title": "title",
          "content": "post content",
          "createdAt": "2019-11-27T23:35:39Z",
          "_version": 10,
          "_lastChangedAt": 1574897753341,
          "_deleted": null
        },
        {
          "id": "post-id",
          "title": "title",
          "content": "post content",
          "createdAt": "2019-11-27T23:35:39Z",
          "_version": 10,
          "_lastChangedAt": 1574897753341,
          "_deleted": null
        }
      ],
      "startedAt": 1575322600038,
      "nextToken": "token"
    }
    """

    let emptyItemsSyncQueryJSON = """
    {
      "items": [],
      "startedAt": 1575322600038,
      "nextToken": "token"
    }
    """

    override func setUp() async throws {
        ModelRegistry.register(modelType: Post.self)
    }

    override func tearDown() async throws {
        ModelRegistry.reset()
    }

    /// - Given: a `Post` Sync query with items, nextToken, and with sync data (startedAt, _version, etc)
    /// - When:
    ///   - the JSON is decoded into `PaginatedList<Post>`
    /// - Then:
    ///   - the result should contain a valid items of type MutationSync<Post>, startedAt, nextToken.
    func testDecodePaginatedList() {
        do {
            let decoder = JSONDecoder(dateDecodingStrategy: ModelDateFormatting.decodingStrategy)

            guard let data = syncQueryJSON.data(using: .utf8) else {
                XCTFail("JSON could not be converted into data")
                return
            }
            let paginatedList = try decoder.decode(PaginatedList<Post>.self, from: data)
            XCTAssertNotNil(paginatedList)
            XCTAssertNotNil(paginatedList.startedAt)
            XCTAssertNotNil(paginatedList.nextToken)
            XCTAssertNotNil(paginatedList.items)
            XCTAssert(!paginatedList.items.isEmpty)
            XCTAssert(paginatedList.items[0].model.title == "title")
            XCTAssert(paginatedList.items[0].syncMetadata.version == 10)
            XCTAssert(paginatedList.items[0].syncMetadata.lastChangedAt == 1_574_897_753_341)
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    func testDecodePaginatedListFromEmptyItems() {
        do {
            let decoder = JSONDecoder(dateDecodingStrategy: ModelDateFormatting.decodingStrategy)

            guard let data = emptyItemsSyncQueryJSON.data(using: .utf8) else {
                XCTFail("JSON could not be converted into data")
                return
            }
            let paginatedList = try decoder.decode(PaginatedList<Post>.self, from: data)
            XCTAssertNotNil(paginatedList)
            XCTAssertNotNil(paginatedList.startedAt)
            XCTAssert(paginatedList.startedAt == 1_575_322_600_038)
            XCTAssertNotNil(paginatedList.nextToken)
            XCTAssert(paginatedList.nextToken == "token")
            XCTAssert(paginatedList.items.isEmpty)
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

}
