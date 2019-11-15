//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
import Vision
@testable import CoreMLPredictionsPlugin

class CoreMLVisionAdapterTests: XCTestCase {

    var coreMLVisionAdapter: CoreMLVisionAdapter!

    override func setUp() {
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

}
