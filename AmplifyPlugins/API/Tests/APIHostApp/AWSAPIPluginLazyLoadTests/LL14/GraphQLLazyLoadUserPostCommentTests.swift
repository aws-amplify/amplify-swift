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

final class GraphQLLazyLoadUserPostCommentTests: GraphQLLazyLoadBaseTest {

    func testConfigure() async throws {
        await setup(withModels: UserPostCommentModels(), logLevel: .verbose)
    }

    func testSaveUser() async throws {
        await setup(withModels: UserPostCommentModels())
        let user = User(username: "name")
        try await mutate(.create(user))
    }
    
    func testSaveUserSettings() async throws {
        await setup(withModels: UserPostCommentModels())
        let user = User(username: "name")
        let savedUser = try await mutate(.create(user))
        
        let userSettings = UserSettings(language: "en-us", user: savedUser)
        try await mutate(.create(userSettings))
    }
    
    func testSavePost() async throws {
        await setup(withModels: UserPostCommentModels())
        let user = User(username: "name")
        let savedUser = try await mutate(.create(user))
        let post = Post(title: "title", rating: 1, status: .active, author: savedUser)
        try await mutate(.create(post))
    }
    
    func testSaveComment() async throws {
        await setup(withModels: UserPostCommentModels())
        let user = User(username: "name")
        let savedUser = try await mutate(.create(user))
        let post = Post(title: "title", rating: 1, status: .active, author: savedUser)
        let savedPost = try await mutate(.create(post))
        
        let comment = Comment(content: "content", post: savedPost, author: savedUser)
        try await mutate(.create(comment))
    }
    
    func testQueryComment() async throws {
        await setup(withModels: UserPostCommentModels())
        let user = User(username: "name")
        let savedUser = try await mutate(.create(user))
        let post = Post(title: "title", rating: 1, status: .active, author: savedUser)
        let savedPost = try await mutate(.create(post))
        let comment = Comment(content: "content", post: savedPost, author: savedUser)
        let savedComment = try await mutate(.create(comment))
        
        let response = try await Amplify.API.query(request: .get(Comment.self, byId: comment.id))
        guard case .success(let queriedComment) = response,
              let queriedComment = queriedComment else {
            return
        }
        XCTAssertEqual(queriedComment.id, savedComment.id)
    }
}

extension GraphQLLazyLoadUserPostCommentTests {
    typealias User = User14
    typealias Post = Post14
    typealias Comment = Comment14
    typealias UserSettings = UserSettings14
    
    struct UserPostCommentModels: AmplifyModelRegistration {
        public let version: String = "version"
        func registerModels(registry: ModelRegistry.Type) {
            ModelRegistry.register(modelType: User14.self)
            ModelRegistry.register(modelType: Post14.self)
            ModelRegistry.register(modelType: Comment14.self)
            ModelRegistry.register(modelType: UserSettings14.self)
        }
    }
}
