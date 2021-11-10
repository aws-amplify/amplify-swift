//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import XCTest

@testable import Amplify
@testable import AmplifyTestCommon

class QueryPredicateEvaluateGeneratedEnumTests: XCTestCase {

    func testEnumNotEqual_True() throws {
        let predicate = Post.keys.status.ne(PostStatus.published)
        let instance = Post(title: "title",
                            content: "content",
                            createdAt: .now(),
                            updatedAt: .now(),
                            status: .published)

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testEnumNotEqual_False() throws {
        let predicate = Post.keys.status.ne(PostStatus.published)
        let instance = Post(title: "title",
                            content: "content",
                            createdAt: .now(),
                            updatedAt: .now(),
                            status: .draft)

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssert(evaluation)
    }

    func testEnumEquals_True() throws {
        let predicate = Post.keys.status.eq(PostStatus.published)
        let instance = Post(title: "title",
                            content: "content",
                            createdAt: .now(),
                            updatedAt: .now(),
                            status: .published)

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssert(evaluation)
    }

    func testEnumEquals_False() throws {
        let predicate = Post.keys.status.eq(PostStatus.published)
        let instance = Post(title: "title",
                            content: "content",
                            createdAt: .now(),
                            updatedAt: .now(),
                            status: .draft)

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }
}
