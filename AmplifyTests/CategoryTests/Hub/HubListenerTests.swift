//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import XCTest

@testable import AmplifyTestCommon

// `@unchecked Sendable`: `XCTestCase` is not `Sendable`, but the test body is captured by the
// `@Sendable` closures the API now takes. XCTest runs one test at a time.
class HubListenerTests: XCTestCase, @unchecked Sendable {

    /// Given: A configured hub, and a category API that takes a listener callback
    /// When: I invoke the API with a callback
    /// Then: I receive callbacks
    func testListen() {
    }
}
