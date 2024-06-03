//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import XCTest
@testable import Amplify

final class GraphQLPostPerson41Tests: AWSAPIPluginGen2GraphQLBaseTest {

    // Code Snippet for
    // https://docs.amplify.aws/swift/build-a-backend/data/data-modeling/identifiers/
    func testCodeSnippet() async throws {
        await setup(withModels: PostPerson41Models())

        let author = Person()
        _ = try await Amplify.API.mutate(request: .create(author))
        let editor = Person()
        _ = try await Amplify.API.mutate(request: .create(editor))
        let post = Post(
            title: "title",
            content: "content",
            author: author,
            editor: editor)
        _ = try await Amplify.API.mutate(request: .create(post))

        // Code Snippet Begins
        do {
            guard let queriedPost = try await Amplify.API.query(
                request: .get(
                    Post.self,
                    byIdentifier: post.identifier)).get() else {
                print("Missing post")
                // Code Snippet Ends
                XCTFail("Missing post")
                // Code Snippet Begins
                return
            }

            let loadedAuthor = try await queriedPost.author
            let loadedEditor = try await queriedPost.editor
            // Code Snippet Ends
            XCTAssertEqual(loadedAuthor?.id, author.id)
            XCTAssertEqual(loadedEditor?.id, editor.id)
            // Code Snippet Begins
        } catch {
            print("Failed to fetch post, author, or editor", error)
            // Code Snippet Ends
            XCTFail("Failed to fetch post, author, or editor \(error)")
            // Code Snippet Begins
        }
    }
}

extension GraphQLPostPerson41Tests: DefaultLogger { }

extension GraphQLPostPerson41Tests {
    typealias Post = Post41
    typealias Person = Person41

    struct PostPerson41Models: AmplifyModelRegistration {
        public let version: String = "version"
        func registerModels(registry: ModelRegistry.Type) {
            ModelRegistry.register(modelType: Post41.self)
            ModelRegistry.register(modelType: Person41.self)
        }
    }
}
