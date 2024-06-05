//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import XCTest
@testable import Amplify

final class GraphQLPostVideoPrivacySettings2Tests: AWSAPIPluginGen2GraphQLBaseTest {

    // Code Snippet for
    // https://docs.amplify.aws/swift/build-a-backend/data/data-modeling/add-fields/#specify-a-custom-field-type
    func testCreate() async throws {
        await setup(withModels: PostVideoPrivacySettings2Models())

        // Code Snippet Begins
        let post = Post(
            content: "hello",
            privacySetting: .private)
        let createdPost = try await Amplify.API.mutate(request: .create(post)).get()

        // Code Snippet Ends
        XCTAssertEqual(createdPost.id, post.id)
    }
}

extension GraphQLPostVideoPrivacySettings2Tests: DefaultLogger { }

extension GraphQLPostVideoPrivacySettings2Tests {
    typealias Post = Post2
    typealias Video = Video2

    struct PostVideoPrivacySettings2Models: AmplifyModelRegistration {
        public let version: String = "version"
        func registerModels(registry: ModelRegistry.Type) {
            ModelRegistry.register(modelType: Post2.self)
            ModelRegistry.register(modelType: Video2.self)
        }
    }
}
