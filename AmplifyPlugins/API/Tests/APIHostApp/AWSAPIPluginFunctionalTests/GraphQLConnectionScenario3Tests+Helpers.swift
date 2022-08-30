//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
@testable import AWSAPIPlugin
@testable import Amplify
@testable import APIHostApp

extension GraphQLConnectionScenario3Tests {
    
    func createPost(id: String = UUID().uuidString, title: String) async throws -> Post3? {
        let post = Post3(id: id, title: title)
        var result: Post3?
        let event = try await Amplify.API.mutate(request: .create(post))
            switch event {
                case .success(let post):
                    result = post
                case .failure(let graphQLResponseError):
                    XCTFail("Failed with error: \(graphQLResponseError)")
                }
        return result
    }

    func createComment(id: String = UUID().uuidString, postID: String, content: String) async throws -> Comment3? {
        let comment = Comment3(id: id, postID: postID, content: content)
        var result: Comment3?
        let event = try await Amplify.API.mutate(request: .create(comment))
            switch event {
                case .success(let comment):
                    result = comment
                case .failure(let graphQLResponseError):
                XCTFail("Failed with error: \(graphQLResponseError)")
                }
        return result
    }

    func mutatePost(post: Post3) async throws -> Post3? {
        var result: Post3?
        let event = try await Amplify.API.mutate(request: .update(post))
            switch event {
            case .success(let post):
                result = post
            case .failure(let graphQLResponseError):
                XCTFail("Failed with error: \(graphQLResponseError)")
            }
        return result
    }

    func deletePost(post: Post3) async throws -> Post3? {
        var result: Post3?
        let event = try await Amplify.API.mutate(request: .delete(post))
            switch event {
            case .success(let post):
                result = post
            case .failure(let graphQLResponseError):
                XCTFail("Failed with error: \(graphQLResponseError)")
            }
        return result
    }
}
