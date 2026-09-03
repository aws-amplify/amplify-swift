//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AWSPluginsCore
import XCTest

// `@unchecked Sendable`: `XCTestCase` is not `Sendable`, but the test body is captured by the
// `@Sendable` closures the API now takes. XCTest runs one test at a time.
class AWSAuthorizationTypeIteratorTests: XCTestCase, @unchecked Sendable {

    func testEmptyIterator_hasNextValue_false() throws {
        var iterator = AWSAuthorizationTypeIterator(withValues: [])

        XCTAssertFalse(iterator.hasNext)
        XCTAssertNil(iterator.next())
    }

    func testOneElementIterator_hasNextValue_once() throws {
        var iterator = AWSAuthorizationTypeIterator(withValues: [.designated(.amazonCognitoUserPools)])

        XCTAssertTrue(iterator.hasNext)
        XCTAssertNotNil(iterator.next())

        XCTAssertFalse(iterator.hasNext)
    }

    func testTwoElementsIterator_hasNextValue_twice() throws {
        var iterator = AWSAuthorizationTypeIterator(withValues: [
            .designated(.amazonCognitoUserPools),
            .designated(.apiKey)
        ])

        XCTAssertTrue(iterator.hasNext)
        XCTAssertNotNil(iterator.next())

        XCTAssertTrue(iterator.hasNext)
        XCTAssertNotNil(iterator.next())

        XCTAssertFalse(iterator.hasNext)
    }
}
