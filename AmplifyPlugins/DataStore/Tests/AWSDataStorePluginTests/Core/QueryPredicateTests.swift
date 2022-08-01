//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest

@testable import Amplify
@testable import AmplifyTestCommon
@testable import AWSDataStorePlugin

class QueryPredicateTests: XCTestCase {

    /// it should create a simple `QueryPredicateOperation`
    func testSingleQueryPredicateOperation() {
        let post = Post.keys
        let predicate = post.draft.eq(true)

        XCTAssertEqual(predicate, post.draft == true)
        XCTAssertEqual(predicate, QueryPredicateOperation(field: "draft", operator: .equals(true)))
    }

    /// it should create a simple `QueryPredicateGroup`
    func testSingleQueryPredicateGroup() {
        let post = Post.keys
        let predicate = post.draft.eq(true).and(post.id.ne(nil))

        let expected = QueryPredicateGroup(
            type: .and,
            predicates: [
                QueryPredicateOperation(field: "draft", operator: .equals(true)),
                QueryPredicateOperation(field: "id", operator: .notEqual(nil))
            ]
        )

        XCTAssertEqual(predicate, expected)
    }

    /// it should create a valid `QueryPredicateOperation` with nested predicates
    func testQueryPredicateGroupWithNestedPredicates() {
        let post = Post.keys

        let predicate = post.draft.eq(true)
            .and(post.id.ne(nil))
            .and(post.title.beginsWith("gelato").or(post.title.beginsWith("ice cream")))
            .and(not(post.content.contains("italia")))

        let expected = QueryPredicateGroup(
            type: .and,
            predicates: [
                QueryPredicateOperation(field: "draft", operator: .equals(true)),
                QueryPredicateOperation(field: "id", operator: .notEqual(nil)),
                QueryPredicateGroup(
                    type: .or,
                    predicates: [
                        QueryPredicateOperation(field: "title", operator: .beginsWith("gelato")),
                        QueryPredicateOperation(field: "title", operator: .beginsWith("ice cream"))
                    ]
                ),
                QueryPredicateGroup(
                    type: .not,
                    predicates: [
                        QueryPredicateOperation(field: "content", operator: .contains("italia"))
                    ]
                )
            ]
        )
        XCTAssert(predicate == expected)
    }

    /// it should verify that predicates created using functions match their operators
    func testQueryPredicateOperationFunctionsMatchOperators() {
        let post = Post.keys
        XCTAssertEqual(post.id.eq("id"), post.id == "id")
        XCTAssertEqual(post.id.contains("id"), post.id ~= "id")
        XCTAssertEqual(post.rating.ge(1), post.rating >= 1)
        XCTAssertEqual(post.rating.gt(2), post.rating > 2)
        XCTAssertEqual(post.rating.le(3), post.rating <= 3)
        XCTAssertEqual(post.rating.lt(4), post.rating < 4)
        XCTAssertEqual(post.id.ne(nil), post.id != nil)
    }

    /// it should verify that predicate groups created using functions match their operators
    func testQueryPredicateGroupFunctionsMatchOperators() {
        let post = Post.keys
        XCTAssertEqual(
            post.id.ne(nil).and(post.id.eq("id")),
            post.id != nil && post.id == "id"
        )
        XCTAssertEqual(
            post.id.ne(nil).or(post.id.eq("id")),
            post.id != nil || post.id == "id"
        )
        XCTAssertEqual(
            not(post.id.eq("id")),
            !(post.id == "id")
        )
    }

    /// it should verify that predicate groups of the same type match their operators
    func testQueryPredicateNestedGroupOfSameTypeFunctionsMatchOperators() {
        let post = Post.keys
        XCTAssertEqual(
            post.id.ne(nil).and(post.id.eq("id")).and(post.rating.ge(0)),
            post.id != nil && post.id == "id" && post.rating >= 0
        )
        XCTAssertEqual(
            post.id.ne(nil).or(post.id.eq("id")).or(post.rating.ge(0)),
            post.id != nil || post.id == "id" || post.rating >= 0
        )
        XCTAssertEqual(
            not(post.id.eq("id").and(post.id.ne(nil))),
            !(post.id == "id" && post.id != nil)
        )
    }

    /// it should verify that predicate groups of the different types match their operators
    func testQueryPredicateNestedGroupOfDifferentTypeFunctionsMatchOperators() {
        let post = Post.keys
        XCTAssertEqual(
            post.id.ne(nil).and(post.id.eq("id")).or(post.rating.ge(0)),
            post.id != nil && post.id == "id" || post.rating >= 0
        )
        XCTAssertEqual(
            post.id.ne(nil).or(post.id.eq("id")).and(post.rating.ge(0)),
            (post.id != nil || post.id == "id") && post.rating >= 0
        )
    }

    /// it should verify that complex predicate groups created using functions match their operators
    func testQueryPredicateGroupWithNestedPredicatesMatchesOperators() {
        let post = Post.keys

        let funcationPredicate = post.draft.eq(true)
            .and(post.id.ne(nil))
            .and(post.title.beginsWith("gelato").or(post.title.beginsWith("ice cream")))
            .and(not(post.updatedAt.eq(nil)))

        let operatorPredicate = post.draft == true
            && post.id != nil
            && (post.title.beginsWith("gelato") || post.title.beginsWith("ice cream"))
            && !(post.updatedAt == nil)

        XCTAssertEqual(funcationPredicate, operatorPredicate)
    }

}
