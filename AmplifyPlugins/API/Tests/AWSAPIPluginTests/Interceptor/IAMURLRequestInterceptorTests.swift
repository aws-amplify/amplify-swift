//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest

// `@unchecked Sendable`: `XCTestCase` is not `Sendable`, but the test body is captured by the
// `@Sendable` closures the API now takes. XCTest runs one test at a time.
class IAMURLRequestInterceptorTests: XCTestCase, @unchecked Sendable {
    func testClassMustNotBeEmptyOrSwiftFormatWillCrash() {
        // TODO implement code
    }
}
