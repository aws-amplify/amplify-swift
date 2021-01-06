//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
import Amplify
@testable import CoreMLPredictionsPlugin

class CoreMLPredictionsPluginTests: CoreMLPredictionsPluginTestBase {

    func testPluginInterpretText() {
        let operation = coreMLPredictionsPlugin.interpret(text: "",
                                                          options: nil,
                                                          listener: nil)
        XCTAssertNotNil(operation, "Should return a valid operation")
        XCTAssertEqual(queue.size, 1)
    }

}
