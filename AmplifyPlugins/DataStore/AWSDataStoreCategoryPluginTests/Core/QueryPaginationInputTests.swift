//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest

@testable import Amplify
@testable import AWSDataStorePlugin

class QueryPaginationInputTests: XCTestCase {

    /// - Given: a `QueryPaginationInput`
    /// - When:
    ///   - the `page` is `0`
    ///   - the `limit` is omitted (default)
    /// - Then:
    ///   - check if the generated SQL statement has the correct parameters
    func testQueryPaginationInputWithDefaultLimit() {
        let paginationInput = QueryPaginationInput.page(0)
        XCTAssertEqual(paginationInput.sqlStatement, "limit 100 offset 0")
    }

    /// - Given: a `QueryPaginationInput`
    /// - When:
    ///   - the `page` is `2`
    ///   - the `limit` is omitted (default)
    /// - Then:
    ///   - check if the generated SQL statement has the correct parameters
    func testQueryPaginationInputCustomPageWithDefaultLimit() {
        let paginationInput = QueryPaginationInput.page(2)
        XCTAssertEqual(paginationInput.sqlStatement, "limit 100 offset 200")
    }

    /// - Given: a `QueryPaginationInput`
    /// - When:
    ///   - the `page` is `0`
    ///   - the `limit` is `20`
    /// - Then:
    ///   - check if the generated SQL statement has the correct parameters
    func testQueryPaginationInputWithCustomLimit() {
        let paginationInput = QueryPaginationInput.page(0, limit: 20)
        XCTAssertEqual(paginationInput.sqlStatement, "limit 20 offset 0")
    }

    /// - Given: a `QueryPaginationInput`
    /// - When:
    ///   - the `page` is `2`
    ///   - the `limit` is `20`
    /// - Then:
    ///   - check if the generated SQL statement has the correct parameters
    func testQueryPaginationInputCustomPageWithCustomLimit() {
        let paginationInput = QueryPaginationInput.page(2, limit: 20)
        XCTAssertEqual(paginationInput.sqlStatement, "limit 20 offset 40")
    }

    /// - Given: a `QueryPaginationInput`
    /// - When:
    ///   - it's created with `.firstPage`
    /// - Then:
    ///   - check if the generated SQL statement has the correct parameters
    func testQueryPaginationInputFirstPage() {
        let paginationInput = QueryPaginationInput.firstPage
        XCTAssertEqual(paginationInput.sqlStatement, "limit 100 offset 0")
    }

    /// - Given: a `QueryPaginationInput`
    /// - When:
    ///   - it's created with `.firstResult`
    /// - Then:
    ///   - check if the generated SQL statement has the correct parameters
    func testQueryPaginationInputFirstResult() {
        let paginationInput = QueryPaginationInput.firstResult
        XCTAssertEqual(paginationInput.sqlStatement, "limit 1 offset 0")
    }

}
