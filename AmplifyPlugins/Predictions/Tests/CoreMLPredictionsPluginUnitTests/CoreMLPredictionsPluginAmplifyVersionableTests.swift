//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

#if canImport(Speech) && canImport(Vision) && !os(tvOS)
import CoreMLPredictionsPlugin
import XCTest

// swiftlint:disable:next type_name
// `@unchecked Sendable`: `XCTestCase` is not `Sendable`, but the test body is captured by the
// `@Sendable` closures the API now takes. XCTest runs one test at a time.
class CoreMLPredictionsPluginAmplifyVersionableTests: XCTestCase, @unchecked Sendable {

    func testVersionExists() {
        let plugin = CoreMLPredictionsPlugin()
        XCTAssertNotNil(plugin.version)
    }

}
#endif
