//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
@testable import Amplify
@testable import AmplifyTestCommon
@testable import AWSPluginsCore

class ModelGraphQLTests: XCTestCase {

    /// - Given: a `Model` type
    /// - When:
    ///    - the model is of type `Post`
    ///    - the model is initialized with value except `updatedAt` is set to nil
    /// - Then:
    ///    - check if the generated GraphQLInput is valid input:
    ///      - fields other than `updatedAt` has the correct value in them
    ///      - `updatedAt` is nil
    func testPostModelToGraphQLInputSuccess() throws {
        let date: Temporal.DateTime = .now()
        let status = PostStatus.published
        let post = Post(id: "id",
                        title: "title",
                        content: "content",
                        createdAt: date,
                        draft: true,
                        rating: 5.0,
                        status: status)

        let graphQLInput = post.graphQLInput

        XCTAssertEqual(graphQLInput["title"] as? String, post.title)
        XCTAssertEqual(graphQLInput["content"] as? String, post.content)
        XCTAssertEqual(graphQLInput["createdAt"] as? String, post.createdAt.iso8601String)
        XCTAssertEqual(graphQLInput["draft"] as? Bool, post.draft)
        XCTAssertEqual(graphQLInput["rating"] as? Double, post.rating)
        XCTAssertEqual(graphQLInput["status"] as? String, status.rawValue)

        XCTAssertTrue(graphQLInput.keys.contains("updatedAt"))
        XCTAssertNil(graphQLInput["updatedAt"]!)
    }
}
