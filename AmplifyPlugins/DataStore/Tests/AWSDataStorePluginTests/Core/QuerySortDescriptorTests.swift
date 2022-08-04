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
@testable import AmplifyTestCommon
@testable import AWSDataStorePlugin

class QuerySortDescriptorTests: XCTestCase {

    func testAscendingSort() {
        let fieldName = "fieldName"
        let sortDescriptor = QuerySortDescriptor(fieldName: fieldName, order: .ascending)
        XCTAssertEqual(sortDescriptor.fieldName, fieldName)
        XCTAssertEqual(sortDescriptor.order, QuerySortOrder.ascending)
    }

    func testDescendingSort() {
        let fieldName = "fieldName"
        let sortDescriptor = QuerySortDescriptor(fieldName: fieldName, order: .descending)
        XCTAssertEqual(sortDescriptor.fieldName, fieldName)
        XCTAssertEqual(sortDescriptor.order, QuerySortOrder.descending)
    }

    func testSortStatementFromArray() {
        let fieldName1 = "fieldName1"
        let sortDescriptor1 = QuerySortDescriptor(fieldName: fieldName1, order: .ascending)

        let fieldName2 = "fieldName2"
        let sortDescriptor2 = QuerySortDescriptor(fieldName: fieldName2, order: .descending)

        let sortDescriptors = [sortDescriptor1, sortDescriptor2]
        let statement = sortDescriptors.sortStatement(namespace: "root")
        let expectedStatement = "\"root\".\"fieldName1\" asc, \"root\".\"fieldName2\" desc"
        XCTAssertEqual(statement, expectedStatement)
    }

    func testSortStatementFromSingleItmeArray() {
        let fieldName1 = "fieldName1"
        let sortDescriptor1 = QuerySortDescriptor(fieldName: fieldName1, order: .ascending)
        let sortDescriptors = [sortDescriptor1]
        let statement = sortDescriptors.sortStatement(namespace: "root")
        let expectedStatement = "\"root\".\"fieldName1\" asc"
        XCTAssertEqual(statement, expectedStatement)
    }

    func testConversionOfQuerySortInput() {
        let querySortBy1 = QuerySortBy.ascending(Post.CodingKeys.content)
        let querySortBy2 = QuerySortBy.descending(Post.CodingKeys.title)
        let sortInput = QuerySortInput([querySortBy1, querySortBy2])
        guard let sortDescriptors = sortInput.asSortDescriptors() else {
            XCTFail("Sort descriptors should no be nil")
            return
        }

        let statement = sortDescriptors.sortStatement(namespace: "root")
        let expectedStatement = "\"root\".\"content\" asc, \"root\".\"title\" desc"
        XCTAssertEqual(statement, expectedStatement)

    }
}
