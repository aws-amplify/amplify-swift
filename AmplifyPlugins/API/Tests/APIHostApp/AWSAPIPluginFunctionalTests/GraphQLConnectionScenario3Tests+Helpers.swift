//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
@testable import AWSAPIPlugin
@testable import Amplify
#if os(watchOS)
@testable import APIWatchApp
#else
@testable import APIHostApp
#endif

extension GraphQLConnectionScenario3Tests {
    
    func createPost(id: String = UUID().uuidString, title: String) async throws -> Post3? {
        let post = Post3(id: id, title: title)
        let event = try await Amplify.API.mutate(request: .create(post))
        switch event {
        case .success(let post):
            return post
        case .failure(let graphQLResponseError):
            throw graphQLResponseError
        }
    }

    func createComment(id: String = UUID().uuidString, postID: String, content: String) async throws -> Comment3? {
        let comment = Comment3(id: id, postID: postID, content: content)
        let event = try await Amplify.API.mutate(request: .create(comment))
        switch event {
        case .success(let comment):
            return comment
        case .failure(let graphQLResponseError):
            throw graphQLResponseError
        }
    }

    func mutatePost(post: Post3) async throws -> Post3? {
        let event = try await Amplify.API.mutate(request: .update(post))
        switch event {
        case .success(let post):
            return post
        case .failure(let graphQLResponseError):
            throw graphQLResponseError
        }
    }

    func deletePost(post: Post3) async throws -> Post3? {
        let event = try await Amplify.API.mutate(request: .delete(post))
        switch event {
        case .success(let post):
            return post
        case .failure(let graphQLResponseError):
            throw graphQLResponseError
        }
    }
}
