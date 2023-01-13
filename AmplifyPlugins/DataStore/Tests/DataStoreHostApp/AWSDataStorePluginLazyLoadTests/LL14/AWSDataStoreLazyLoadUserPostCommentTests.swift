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

final class AWSDataStoreLazyLoadUserPostCommentTests: AWSDataStoreLazyLoadBaseTest {

    func testStart() async throws {
        await setup(withModels: UserPostCommentModels())
        try await startAndWaitForReady()
    }

    func testSaveUser() async throws {
        await setup(withModels: UserPostCommentModels())
        let user = User(username: "name")
        try await saveAndWaitForSync(user)
    }
    
    func testSaveUserSettings() async throws {
        await setup(withModels: UserPostCommentModels())
        let user = User(username: "name")
        let savedUser = try await saveAndWaitForSync(user)
        
        let userSettings = UserSettings(language: "en-us", user: savedUser)
        try await saveAndWaitForSync(userSettings)
    }
    
    func testSavePost() async throws {
        await setup(withModels: UserPostCommentModels())
        let user = User(username: "name")
        let savedUser = try await saveAndWaitForSync(user)
        let post = Post(title: "title", rating: 1, status: .active, author: savedUser)
        try await saveAndWaitForSync(post)
    }
    
    func testSaveComment() async throws {
        await setup(withModels: UserPostCommentModels())
        let user = User(username: "name")
        let savedUser = try await saveAndWaitForSync(user)
        let post = Post(title: "title", rating: 1, status: .active, author: savedUser)
        let savedPost = try await saveAndWaitForSync(post)
        
        let comment = Comment(content: "content", post: savedPost, author: savedUser)
        try await saveAndWaitForSync(comment)
    }
}


extension AWSDataStoreLazyLoadUserPostCommentTests {
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
