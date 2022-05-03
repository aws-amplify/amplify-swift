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
    override func setUp() {
        ModelRegistry.register(modelType: Post.self)
    }

    func testEnumNotEqual_False() throws {
        let predicate = Post.keys.status.ne(PostStatus.published)
        let instance = Post(title: "title",
                            content: "content",
                            createdAt: .now(),
                            updatedAt: .now(),
                            status: .published)

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testEnumNotEqual_True() throws {
        let predicate = Post.keys.status.ne(PostStatus.published)
        let instance = Post(title: "title",
                            content: "content",
                            createdAt: .now(),
                            updatedAt: .now(),
                            status: .draft)

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertTrue(evaluation)
    }

    func testEnumEquals_True() throws {
        let predicate = Post.keys.status.eq(PostStatus.published)
        let instance = Post(title: "title",
                            content: "content",
                            createdAt: .now(),
                            updatedAt: .now(),
                            status: .published)

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertTrue(evaluation)
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

    /// Draft is not greater than published, evaluates to false
    func testEnumToStringGreaterThan_False() throws {
        let predicate = Post.keys.status.gt(PostStatus.published.rawValue)
        let instance = Post(title: "title",
                            content: "content",
                            createdAt: .now(),
                            updatedAt: .now(),
                            status: .draft)

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    /// Published is greater than draft, evaluates to true
    func testEnumToStringGreaterThan_True() throws {
        let predicate = Post.keys.status.gt(PostStatus.draft.rawValue)
        let instance = Post(title: "title",
                            content: "content",
                            createdAt: .now(),
                            updatedAt: .now(),
                            status: .published)

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertTrue(evaluation)
    }

    /// Published is not less than draft, evalutates to false
    func testEnumToStringLessThan_False() throws {
        let predicate = Post.keys.status.lt(PostStatus.draft.rawValue)
        let instance = Post(title: "title",
                            content: "content",
                            createdAt: .now(),
                            updatedAt: .now(),
                            status: .published)

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    /// Draft is less than publshed, evaluates to true
    func testEnumToStringLessThan_True() throws {
        let predicate = Post.keys.status.lt(PostStatus.published.rawValue)
        let instance = Post(title: "title",
                            content: "content",
                            createdAt: .now(),
                            updatedAt: .now(),
                            status: .draft)

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertTrue(evaluation)
    }
}
