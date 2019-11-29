//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Combine
import XCTest

@testable import Amplify
@testable import AmplifyTestCommon
@testable import AWSDataStoreCategoryPlugin

class MutationSyncMetadataTests: BaseDataStoreTests {

    let postSyncJSON = """
    {
      "id": "post-id",
      "title": "post title",
      "content": "post content",
      "createdAt": "2019-11-28T16:51:20+0000",
      "updatedAt": null,
      "rating": 4.5,
      "draft": false,
      "comments": [],
      "_deleted": null,
      "_lastChangedAt": 1574960021,
      "_version": 3,
      "__typename": "Post"
    }
    """

    /// - Given: a `Post` json with sync data
    /// - When:
    ///   - the JSON is decoded into `MutationSync<Post>`
    /// - Then:
    ///   - the tuple should contain a valid `Post` and its `MutationSyncMetadata`
    func testDecodeMutationSync() {
        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601

            guard let data = postSyncJSON.data(using: .utf8) else {
                XCTFail("JSON could not be converted into data")
                return
            }
            let mutationSync = try decoder.decode(MutationSync<Post>.self, from: data)
            let model = mutationSync.model
            XCTAssertEqual(model.id, "post-id")

            let syncMetadata = mutationSync.syncMetadata
            XCTAssertEqual(syncMetadata.deleted, false)
            XCTAssertEqual(syncMetadata.lastChangedAt, 1_574_960_021)
            XCTAssertEqual(syncMetadata.version, 3)
        } catch {
            XCTFail(error.localizedDescription)
        }

    }

    /// - Given: a `Post` json with sync data
    /// - When:
    ///   - the JSON is decoded into `MutationSync<AnyModel>`
    /// - Then:
    ///   - the tuple should contain a valid `AnyModel` and its `MutationSyncMetadata`
    ///   - the `AnyModel` should be backed by a `Post`
    func testDecodeAnyModelMutationSync() {
        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601

            guard let data = postSyncJSON.data(using: .utf8) else {
                XCTFail("JSON could not be converted into data")
                return
            }
            let mutationSync = try decoder.decode(MutationSync<AnyModel>.self, from: data)
            let model = mutationSync.model
            XCTAssertEqual(model.id, "post-id")
            let post = model.instance as? Post
            XCTAssertNotNil(post)

            let syncMetadata = mutationSync.syncMetadata
            XCTAssertEqual(syncMetadata.deleted, false)
            XCTAssertEqual(syncMetadata.lastChangedAt, 1_574_960_021)
            XCTAssertEqual(syncMetadata.version, 3)
        } catch {
            XCTFail(error.localizedDescription)
        }

    }

    /// - Given: a list of `Post` and `MutationSyncMetadata`
    /// - When:
    ///   - the `storageAdapter.queryMutationSync(for:)` is called
    /// - Then:
    ///   - the result should contain a list of `MutationSync`
    ///   - each `MutationSync` represents the correct pair of `Post` and `MutationSyncMetadata`
    func testQueryMutationSync() {
        let expect = expectation(description: "it should create posts and sync metadata")
        // insert some posts
        let posts = stride(from: 0, to: 3, by: 1).map {
            Post(title: "title \($0)", content: "content \($0)")
        }
        populateData(posts)

        // then create sync metadata for them
        let syncMetadataList = posts.map {
            MutationSyncMetadata(id: $0.id,
                                 deleted: false,
                                 lastChangedAt: Int(Date().timeIntervalSince1970),
                                 version: 1)
        }
        populateData(syncMetadataList)

        do {
            let mutationSync = try storageAdapter.queryMutationSync(for: posts)
            mutationSync.forEach {
                XCTAssertEqual($0.model.id, $0.syncMetadata.id)
                let post = $0.model.instance as? Post
                XCTAssertNotNil(post)
            }
            expect.fulfill()
        } catch {
            XCTFail(error.localizedDescription)
            expect.fulfill()
        }
        wait(for: [expect], timeout: 5)
    }
}
