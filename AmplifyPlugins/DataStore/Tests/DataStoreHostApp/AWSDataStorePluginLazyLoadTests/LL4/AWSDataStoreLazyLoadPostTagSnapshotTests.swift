//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Combine
import XCTest

@testable import Amplify
import AWSPluginsCore

extension AWSDataStoreLazyLoadPostTagTests {
    
    func testPostSelectionSets() async throws {
        await setup(withModels: PostTagModels())
        continueAfterFailure = true
        
        // SyncQuery
        let syncRequest = GraphQLRequest<MutationSyncResult>.syncQuery(modelType: Post.self)
        let syncDocument = """
        query SyncPostWithTagsCompositeKeys($limit: Int) {
          syncPostWithTagsCompositeKeys(limit: $limit) {
            items {
              postId
              title
              createdAt
              updatedAt
              __typename
              _version
              _deleted
              _lastChangedAt
            }
            nextToken
            startedAt
          }
        }
        """
        XCTAssertEqual(syncRequest.document, syncDocument)
    }
    
    func testTagSelectionSets() async throws {
        await setup(withModels: PostTagModels())
        continueAfterFailure = true
        
        // SyncQuery
        let syncRequest = GraphQLRequest<MutationSyncResult>.syncQuery(modelType: Tag.self)
        let syncDocument = """
        query SyncTagWithCompositeKeys($limit: Int) {
          syncTagWithCompositeKeys(limit: $limit) {
            items {
              id
              name
              createdAt
              updatedAt
              __typename
              _version
              _deleted
              _lastChangedAt
            }
            nextToken
            startedAt
          }
        }
        """
        XCTAssertEqual(syncRequest.document, syncDocument)
    }
    
    func testPostTagSelectionSets() async throws {
        await setup(withModels: PostTagModels())
        continueAfterFailure = true
        
        // SyncQuery
        let syncRequest = GraphQLRequest<MutationSyncResult>.syncQuery(modelType: PostTag.self)
        let syncDocument = """
        query SyncPostTagsWithCompositeKeys($limit: Int) {
          syncPostTagsWithCompositeKeys(limit: $limit) {
            items {
              id
              createdAt
              updatedAt
              postWithTagsCompositeKey {
                postId
                title
                __typename
                _deleted
              }
              tagWithCompositeKey {
                id
                name
                __typename
                _deleted
              }
              __typename
              _version
              _deleted
              _lastChangedAt
            }
            nextToken
            startedAt
          }
        }
        """
        XCTAssertEqual(syncRequest.document, syncDocument)
    }
}
