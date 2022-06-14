//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
import Vision
@testable import CoreMLPredictionsPlugin

class CoreMLVisionAdapterTests: XCTestCase {

    var coreMLVisionAdapter: CoreMLVisionAdapter!

    override func setUp() async throws {
        coreMLVisionAdapter = CoreMLVisionAdapter()
    }

    func testDetectLabels() {
        let testBundle = Bundle(for: type(of: self))
        guard let url = testBundle.url(forResource: "people", withExtension: "jpg") else {
            return
        }
        let result = coreMLVisionAdapter.detectLabels(url)
        XCTAssertNotNil(result, "The result should be nil")
    }

    func testDetectText() {
        let testBundle = Bundle(for: type(of: self))
        guard let url = testBundle.url(forResource: "screenshotWithText", withExtension: "png") else {
            return
        }
        let result = coreMLVisionAdapter.detectText(url)
        XCTAssertNotNil(result, "The result should be nil")
    }

    func testDetectEntities() {
        let testBundle = Bundle(for: type(of: self))
        guard let url = testBundle.url(forResource: "people", withExtension: "jpg") else {
            return
        }
        let result = coreMLVisionAdapter.detectEntities(url)
        XCTAssertNotNil(result, "The result should be nil")
        XCTAssertTrue(result?.entities.isEmpty != true, "The result should contain values for the image provided.")
    }

}
