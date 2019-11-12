//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
import Vision
@testable import CoreMLPredictionsPlugin

class CoreMLVisionAdaptorTests: XCTestCase {

    var coreMLVisionAdaptor: CoreMLVisionAdaptor!

    override func setUp() {
        coreMLVisionAdaptor = CoreMLVisionAdaptor()
    }

    func testDetectLabels() {
        let testBundle = Bundle(for: type(of: self))
        guard let url = testBundle.url(forResource: "people", withExtension: "jpg") else {
            return
        }
        let result = coreMLVisionAdaptor.detectLabels(url)
        XCTAssertNotNil(result, "The result should be nil")
    }

    func testDetectText() {
        let testBundle = Bundle(for: type(of: self))
        guard let url = testBundle.url(forResource: "screenshotWithText", withExtension: "png") else {
            return
        }
        let result = coreMLVisionAdaptor.detectText(url)
        XCTAssertNotNil(result, "The result should be nil")
    }

}
