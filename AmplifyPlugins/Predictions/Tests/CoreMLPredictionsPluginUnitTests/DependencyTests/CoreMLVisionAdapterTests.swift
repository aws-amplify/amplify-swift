//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

#if canImport(Vision)
import XCTest
import Vision
@testable import CoreMLPredictionsPlugin

class CoreMLVisionAdapterTests: XCTestCase {
    var coreMLVisionAdapter: CoreMLVisionAdapter!

    override func setUp() {
        coreMLVisionAdapter = CoreMLVisionAdapter()
    }

    func testDetectLabels() throws {
        let url = try XCTUnwrap(
            Bundle.module.url(forResource: "people", withExtension: "jpg", subdirectory: "TestImages")
        )
        let result = try coreMLVisionAdapter.detectLabels(url)
        XCTAssertNotNil(result, "The result should be nil")
    }

    func testDetectText() throws {
        let url = try XCTUnwrap(
            Bundle.module.url(forResource: "screenshotWithText", withExtension: "png", subdirectory: "TestImages")
        )
        let result = try coreMLVisionAdapter.detectText(url)
        XCTAssertNotNil(result, "The result should be nil")
    }

    func testDetectEntities() throws {
        let url = try XCTUnwrap(
            Bundle.module.url(forResource: "people", withExtension: "jpg", subdirectory: "TestImages")
        )
        let result = try coreMLVisionAdapter.detectEntities(url)
        XCTAssertNotNil(result, "The result should be nil")
        XCTAssertTrue(result?.entities.isEmpty != true, "The result should contain values for the image provided.")
    }
}
#endif
