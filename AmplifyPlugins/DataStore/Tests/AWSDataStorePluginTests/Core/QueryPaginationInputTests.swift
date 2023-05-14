//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
@testable import Amplify
@testable import AWSDataStorePlugin
import AmplifyTestCommon

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

	/// - Given:  `page` and `limit` local variables inferred to be of type `Int`
	/// - When: Calling `.page(_:limit:)`
	/// - Then: The example should compile by using the `Int` based overload
	func test_queryPaginationInput_inferredInt() {
		let page = 0
		let limit = 42
		let paginationInput = QueryPaginationInput.page(page, limit: limit)
		XCTAssertEqual(paginationInput.sqlStatement, "limit 42 offset 0")
	}

	/// - Given:  `page` and `limit` local variables explicitly typed as `UInt`
	/// - When: Calling `.page(_:limit:)`
	/// - Then: The example should compile by using the `UInt` based overload
	func test_queryPaginationInput_explicitUInt() {
		let page: UInt = 0
		let limit: UInt = 42
		let paginationInput = QueryPaginationInput.page(page, limit: limit)
		XCTAssertEqual(paginationInput.sqlStatement, "limit 42 offset 0")
	}

	/// - Given:  A local `page` variable with a negative value of type `Int`
	/// - When: Calling `.page(_:limit:)`
	/// - Then: An assertion failure should be thrown.
	func test_queryPaginationInput_negativeIntOverload_assertionFailure() throws {
		let page = -1
		let limit = 42
		try XCTAssertThrowFatalError {
			_ = QueryPaginationInput.page(page, limit: limit)
		}
	}
}
