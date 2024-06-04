//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import XCTest
@testable import Amplify

final class GraphQLLocationPostUser1Tests: AWSAPIPluginGen2GraphQLBaseTest {

    // Code Snippet for
    // https://docs.amplify.aws/swift/build-a-backend/data/data-modeling/add-fields/#specify-an-enum-field-type
    func testCodeSnippet() async throws {
        await setup(withModels: PostUserLocation1Models())

        let post = Post(
            location: .init(
                lat: 48.837006,
                long: 8.28245))
        let createdPost = try await Amplify.API.mutate(request: .create(post)).get()
        print("\(createdPost)")

        XCTAssertEqual(createdPost.location?.lat, 48.837006)
        XCTAssertEqual(createdPost.location?.long, 8.28245)
    }
}

extension GraphQLLocationPostUser1Tests: DefaultLogger { }

extension GraphQLLocationPostUser1Tests {
    typealias Post = Post1
    typealias User = User1
    typealias Location = Location1

    struct PostUserLocation1Models: AmplifyModelRegistration {
        public let version: String = "version"
        func registerModels(registry: ModelRegistry.Type) {
            ModelRegistry.register(modelType: Post1.self)
            ModelRegistry.register(modelType: User1.self)
        }
    }
}
