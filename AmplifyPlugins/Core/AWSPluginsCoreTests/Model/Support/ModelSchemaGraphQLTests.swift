//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
@testable import Amplify
@testable import AmplifyTestCommon
@testable import AWSPluginsCore

class ModelSchemaGraphQLTests: XCTestCase {

    func testGraphQLNamesForDeprecatedTodo() throws {
        let todo = DeprecatedTodo.schema

        XCTAssertEqual(todo.graphQLName(queryType: .get), "getDeprecatedTodo")
        XCTAssertEqual(todo.graphQLName(queryType: .list), "listDeprecatedTodos")
        XCTAssertEqual(todo.graphQLName(queryType: .sync), "syncDeprecatedTodos")

        XCTAssertEqual(todo.graphQLName(subscriptionType: .onCreate), "onCreateDeprecatedTodo")
        XCTAssertEqual(todo.graphQLName(subscriptionType: .onUpdate), "onUpdateDeprecatedTodo")
        XCTAssertEqual(todo.graphQLName(subscriptionType: .onDelete), "onDeleteDeprecatedTodo")

        XCTAssertEqual(todo.graphQLName(mutationType: .create), "createDeprecatedTodo")
        XCTAssertEqual(todo.graphQLName(mutationType: .update), "updateDeprecatedTodo")
        XCTAssertEqual(todo.graphQLName(mutationType: .delete), "deleteDeprecatedTodo")
    }

    func testGraphQLNameForWishWithPluralName() {
        let wish = ModelSchema(name: "Wish",
                               pluralName: "Wishes")
        XCTAssertEqual(wish.graphQLName(queryType: .get), "getWish")
        XCTAssertEqual(wish.graphQLName(queryType: .list), "listWishes")
        XCTAssertEqual(wish.graphQLName(queryType: .sync), "syncWishes")

        XCTAssertEqual(wish.graphQLName(subscriptionType: .onCreate), "onCreateWish")
        XCTAssertEqual(wish.graphQLName(subscriptionType: .onUpdate), "onUpdateWish")
        XCTAssertEqual(wish.graphQLName(subscriptionType: .onDelete), "onDeleteWish")

        XCTAssertEqual(wish.graphQLName(mutationType: .create), "createWish")
        XCTAssertEqual(wish.graphQLName(mutationType: .update), "updateWish")
        XCTAssertEqual(wish.graphQLName(mutationType: .delete), "deleteWish")
    }

    func testGraphQLNameForWishWithListPluralName() {
        let wish = ModelSchema(name: "Wish",
                               listPluralName: "Wishes",
                               syncPluralName: "Wishes")
        XCTAssertEqual(wish.graphQLName(queryType: .get), "getWish")
        XCTAssertEqual(wish.graphQLName(queryType: .list), "listWishes")
        XCTAssertEqual(wish.graphQLName(queryType: .sync), "syncWishes")

        XCTAssertEqual(wish.graphQLName(subscriptionType: .onCreate), "onCreateWish")
        XCTAssertEqual(wish.graphQLName(subscriptionType: .onUpdate), "onUpdateWish")
        XCTAssertEqual(wish.graphQLName(subscriptionType: .onDelete), "onDeleteWish")

        XCTAssertEqual(wish.graphQLName(mutationType: .create), "createWish")
        XCTAssertEqual(wish.graphQLName(mutationType: .update), "updateWish")
        XCTAssertEqual(wish.graphQLName(mutationType: .delete), "deleteWish")
    }
}
