//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

#if canImport(Speech) && canImport(Vision)
import XCTest
import CoreMLPredictionsPlugin

// swiftlint:disable:next type_name
class CoreMLPredictionsPluginAmplifyVersionableTests: XCTestCase {

    func testVersionExists() {
        let plugin = CoreMLPredictionsPlugin()
        XCTAssertNotNil(plugin.version)
    }

}
#endif
