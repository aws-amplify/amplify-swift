//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import SQLite
import SQLite3
import XCTest

@testable import Amplify
@testable import AmplifyTestCommon
@testable import AWSDataStorePlugin

// `@unchecked Sendable`: `XCTestCase` is not `Sendable`, but the test body is captured by the
// `@Sendable` closures the API now takes. XCTest runs one test at a time.
class StatementModelTests: XCTestCase, @unchecked Sendable {

    func testDropLastPath_invalidString() throws {
        let path = "post."
        let result = path.dropLastPath()
        XCTAssertEqual(result, "post")
    }

    func testDropLastPath_emptyString() throws {
        let path = ""
        let result = path.dropLastPath()
        XCTAssertEqual(result, "")
    }

    func testDropLastPath_Root() throws {
        let path = "post"
        let result = path.dropLastPath()
        XCTAssertEqual(result, "post")
    }

    func testDropLastPath_OnePath() throws {
        let path = "post.id"
        let result = path.dropLastPath()
        XCTAssertEqual(result, "post")
    }

    func testDropLastPath_Nested() throws {
        let path = "post.blog.id"
        let result = path.dropLastPath()
        XCTAssertEqual(result, "post.blog")
    }

    /// A row step that fails throws its SQLite error instead of crashing the process.
    ///
    /// - Given: a statement that prepares, but fails with an integer overflow whenever it steps
    /// - When:
    ///    - its rows are converted to untyped models
    /// - Then:
    ///    - the step's SQLite error is thrown
    ///
    func testConvertToUntypedModel_whenStepFails_throws() throws {
        let connection = try Connection(.inMemory)
        // abs(INT64_MIN) has no 64-bit result, so SQLite fails it when stepping, not when preparing.
        let statement = try connection.prepare("select abs(-9223372036854775807 - 1)")

        XCTAssertThrowsError(try statement.convertToUntypedModel(
            using: Post.schema,
            statement: SelectStatement(from: Post.schema),
            eagerLoad: true
        )) { error in
            guard let resultError = error as? SQLite.Result,
                  case .error(let message, let code, _) = resultError else {
                XCTFail("Unexpected error: \(error)")
                return
            }
            XCTAssertEqual(code, SQLITE_ERROR)
            XCTAssertEqual(message, "integer overflow")
        }
    }
}
