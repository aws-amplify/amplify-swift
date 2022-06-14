//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Combine
import XCTest

@testable import Amplify
@testable import AmplifyTestCommon
@testable import AWSPluginsCore

class MutationSyncMetadataTests: XCTestCase {

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

    override func setUp() async throws {
        ModelRegistry.register(modelType: Post.self)
    }

    override func tearDown() async throws {
        ModelRegistry.reset()
    }

    /// - Given: a `Post` json with sync data
    /// - When:
    ///   - the JSON is decoded into `MutationSync<Post>`
    /// - Then:
    ///   - the tuple should contain a valid `Post` and its `MutationSyncMetadata`
    func testDecodeMutationSync() {
        do {
            let decoder = JSONDecoder(dateDecodingStrategy: ModelDateFormatting.decodingStrategy)

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
            let decoder = JSONDecoder(dateDecodingStrategy: ModelDateFormatting.decodingStrategy)

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
}
