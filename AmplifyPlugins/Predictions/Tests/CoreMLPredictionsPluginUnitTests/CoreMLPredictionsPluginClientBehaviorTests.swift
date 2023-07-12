//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//
#if canImport(Speech) && canImport(Vision)
import XCTest
import Amplify
@testable import CoreMLPredictionsPlugin

class CoreMLPredictionsPluginTests: CoreMLPredictionsPluginTestBase {
    func testPluginInterpretText() async throws {
        let result = try await coreMLPredictionsPlugin.interpret(
            text: "",
            options: nil
        )

        XCTAssertNotNil(result, "Should return a valid operation")
    }
}
#endif
