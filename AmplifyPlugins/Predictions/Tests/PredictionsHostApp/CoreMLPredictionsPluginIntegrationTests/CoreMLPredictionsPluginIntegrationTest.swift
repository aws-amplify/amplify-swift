//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
import Amplify
import XCTest

class CoreMLPredictionsPluginIntegrationTest: AWSPredictionsPluginTestBase {
    func testIdentify() async throws {
        let testBundle = Bundle(for: type(of: self))
        let url = try XCTUnwrap(testBundle.url(forResource: "people", withExtension: "jpg"))

        let result = try await Amplify.Predictions.identify(
            .labels(type: .all),
            in: url
        )

        XCTAssertNotNil(result, "Result should contain value")
    }
}
