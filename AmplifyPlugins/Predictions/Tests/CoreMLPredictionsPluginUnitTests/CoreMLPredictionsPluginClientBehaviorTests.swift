//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

#if canImport(Speech) && canImport(Vision) && !os(tvOS)
import Amplify
import XCTest
@testable import CoreMLPredictionsPlugin

// `@unchecked Sendable`: `XCTestCase` is not `Sendable`, but the test body is captured by the
// `@Sendable` closures the API now takes. XCTest runs one test at a time.
class CoreMLPredictionsPluginTests: CoreMLPredictionsPluginTestBase, @unchecked Sendable {
    func testPluginInterpretText() async throws {
        let result = try await coreMLPredictionsPlugin.interpret(
            text: "",
            options: nil
        )

        XCTAssertNotNil(result, "Should return a valid operation")
    }
}
#endif
