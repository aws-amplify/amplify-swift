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
    
    /// LazyLoad from queried models
    ///
    /// - Given: Created models
    /// - When:
    ///    - Querying for models
    /// - Then:
    ///    - Traversing from the models to its connected models are successful
    ///
    func testLazyLoad() async throws {
        await setup(withModels: UserPostCommentModels())
        let user = User(username: "name")
        let savedUser = try await mutate(.create(user))
        let userSettings = UserSettings(language: "en-us", user: savedUser)
        try await mutate(.create(userSettings))
        let post = Post(title: "title", rating: 1, status: .active, author: savedUser)
        let savedPost = try await mutate(.create(post))
        let comment = Comment(content: "content", post: savedPost, author: savedUser)
        try await mutate(.create(comment))
        
        // Traverse from User
        let queriedUser = try await query(for: user)!
        try await queriedUser.posts?.fetch()
        XCTAssertEqual(queriedUser.posts?.count, 1)
        try await queriedUser.comments?.fetch()
        XCTAssertEqual(queriedUser.comments?.count, 1)
        // Cannot traverse from User to settings since no FK is set on the User
        //let queriedUserSettings = try await queriedUser.settings
        //XCTAssertNotNil(queriedUserSettings)
        
        // Traverse from UserSettings
        let queriedSettings = try await query(for: userSettings)!
        let queriedSettingsUser = try await queriedSettings.user
        XCTAssertEqual(queriedSettingsUser.id, user.id)

        // Traverse from Post
        let queriedPost = try await query(for: post)!
        try await queriedPost.comments?.fetch()
        XCTAssertEqual(queriedPost.comments?.count, 1)
        let queriedPostUser = try await queriedPost.author
        XCTAssertEqual(queriedPostUser.id, user.id)

        // Traverse from Comment
        let queriedComment = try await query(for: comment)!
        let queriedCommentPost = try await queriedComment.post
        XCTAssertEqual(queriedCommentPost?.id, post.id)
        let queriedCommentUser = try await queriedComment.author
        XCTAssertEqual(queriedCommentUser.id, user.id)

        // Clean up - delete the saved models
        try await mutate(.delete(comment))
        try await assertModelDoesNotExist(comment)
        try await mutate(.delete(post))
        try await assertModelDoesNotExist(post)
        try await mutate(.delete(userSettings))
        try await assertModelDoesNotExist(userSettings)
        try await mutate(.delete(user))
        try await assertModelDoesNotExist(user)
    }
    
    func testIncludesNestedModels() async throws {
        await setup(withModels: UserPostCommentModels())
        let user = User(username: "name")
        let savedUser = try await mutate(.create(user))
        let userSettings = UserSettings(language: "en-us", user: savedUser)
        try await mutate(.create(userSettings))
        let post = Post(title: "title", rating: 1, status: .active, author: savedUser)
        let savedPost = try await mutate(.create(post))
        let comment = Comment(content: "content", post: savedPost, author: savedUser)
        try await mutate(.create(comment))
        
        guard let queriedUser = try await query(.get(User.self,
                                                     byIdentifier: user.id,
                                                     includes: { user in [user.comments,
                                                                          user.posts] })) else {
            XCTFail("Could not perform nested query for User")
            return
        }
        
        XCTAssertEqual(queriedUser.posts?.count, 1)
        XCTAssertEqual(queriedUser.comments?.count, 1)
    }
    
    func testSaveUserWithUserSettings() async throws {
        await setup(withModels: UserPostCommentModels())
        let user = User(username: "name")
        var savedUser = try await mutate(.create(user))
        let userSettings = UserSettings(language: "en-us", user: savedUser)
        try await mutate(.create(userSettings))
        
        // Update the User with the UserSettings (this is required for bi-directional has-one belongs-to)
        savedUser.setSettings(userSettings)
        try await mutate(.update(savedUser))
        
        let queriedUser = try await query(for: user)!
        let queriedUserSettings = try await queriedUser.settings
        XCTAssertNotNil(queriedUserSettings)
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
