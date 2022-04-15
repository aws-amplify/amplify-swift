//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import UIKit
@testable import Amplify
import AWSPredictionsPlugin
import AWSRekognition
import XCTest

class IdentifyBasicIntegrationTests: AWSPredictionsPluginTestBase {

    /// Given: An Image
    /// When: Image is sent to Rekognition
    /// Then: The operation completes successfully
    func testIdentifyLabels() {
        let testBundle = Bundle(for: type(of: self))
        guard let url = testBundle.url(forResource: "testImageLabels", withExtension: "jpg") else {
            XCTFail("Unable to find image")
            return
        }
        let completeInvoked = expectation(description: "Completed is invoked")

        let operation = Amplify.Predictions.identify(type: .detectLabels(.labels),
                                                     image: url,
                                                     options: PredictionsIdentifyRequest.Options()) { event in
            switch event {
            case .success:
                completeInvoked.fulfill()
            case .failure(let error):
                XCTFail("Failed with \(error)")
            }
        }

        XCTAssertNotNil(operation)
        waitForExpectations(timeout: networkTimeout)
    }

    func testIdentifyModerationLabels() {
        let testBundle = Bundle(for: type(of: self))
        guard let url = testBundle.url(forResource: "testImageLabels", withExtension: "jpg") else {
            XCTFail("Unable to find image")
            return
        }
        let completeInvoked = expectation(description: "Completed is invoked")

        let operation = Amplify.Predictions.identify(type: .detectLabels(.moderation),
                                                     image: url,
                                                     options: PredictionsIdentifyRequest.Options()) { event in
            switch event {
            case .success:
                completeInvoked.fulfill()
            case .failure(let error):
                XCTFail("Failed with \(error)")
            }
        }

        XCTAssertNotNil(operation)
        waitForExpectations(timeout: networkTimeout)
    }

    func testIdentifyAllLabels() {
        let testBundle = Bundle(for: type(of: self))
        guard let url = testBundle.url(forResource: "testImageLabels", withExtension: "jpg") else {
            XCTFail("Unable to find image")
            return
        }
        let completeInvoked = expectation(description: "Completed is invoked")

        let operation = Amplify.Predictions.identify(type: .detectLabels(.all),
                                                     image: url,
                                                     options: PredictionsIdentifyRequest.Options()) { event in
            switch event {
            case .success:
                completeInvoked.fulfill()
            case .failure(let error):
                XCTFail("Failed with \(error)")
            }
        }

        XCTAssertNotNil(operation)
        waitForExpectations(timeout: networkTimeout)
    }

    func testIdentifyCelebrities() {
        let testBundle = Bundle(for: type(of: self))
        guard let url = testBundle.url(forResource: "testImageCeleb", withExtension: "jpg") else {
            XCTFail("Unable to find image")
            return
        }
        let completeInvoked = expectation(description: "Completed is invoked")

        let operation = Amplify.Predictions.identify(type: .detectCelebrity,
                                                     image: url,
                                                     options: PredictionsIdentifyRequest.Options()) { event in
            switch event {
            case .success:
                completeInvoked.fulfill()
            case .failure(let error):
                XCTFail("Failed with \(error)")
            }
        }

        XCTAssertNotNil(operation)
        waitForExpectations(timeout: networkTimeout)
    }

    func testIdentifyEntityMatches() {
        let testBundle = Bundle(for: type(of: self))
        guard let url = testBundle.url(forResource: "testImageEntities", withExtension: "jpg") else {
            XCTFail("Unable to find image")
            return
        }
        let completeInvoked = expectation(description: "Completed is invoked")

        let operation = Amplify.Predictions.identify(type: .detectEntities,
                                                     image: url,
                                                     options: PredictionsIdentifyRequest.Options()) { event in
            switch event {
            case .success:
                completeInvoked.fulfill()
            case .failure(let error):
                XCTFail("Failed with \(error)")
            }
        }

        XCTAssertNotNil(operation)
        waitForExpectations(timeout: networkTimeout)
    }

    func testIdentifyEntities() {
        let testBundle = Bundle(for: type(of: self))
        guard let url = testBundle.url(forResource: "testImageEntities", withExtension: "jpg") else {
            XCTFail("Unable to find image")
            return
        }
        let completeInvoked = expectation(description: "Completed is invoked")

        let operation = Amplify.Predictions.identify(type: .detectEntities,
                                                     image: url,
                                                     options: PredictionsIdentifyRequest.Options()) { event in
            switch event {
            case .success:
                completeInvoked.fulfill()
            case .failure(let error):
                XCTFail("Failed with \(error)")
            }
        }

        XCTAssertNotNil(operation)
        waitForExpectations(timeout: networkTimeout)
    }

    func testIdentifyTextPlain() {
        let testBundle = Bundle(for: type(of: self))
        guard let url = testBundle.url(forResource: "testImageText", withExtension: "jpg") else {
            XCTFail("Unable to find image")
            return
        }
        let completeInvoked = expectation(description: "Completed is invoked")

        let operation = Amplify.Predictions.identify(type: .detectText(.plain),
                                                     image: url,
                                                     options: PredictionsIdentifyRequest.Options()) { event in
            switch event {
            case .success:
                completeInvoked.fulfill()
            case .failure(let error):
                XCTFail("Failed with \(error)")
            }
        }

        XCTAssertNotNil(operation)
        waitForExpectations(timeout: networkTimeout)
    }

    /// Given:
    /// - An Image with plain text, form and table
    /// When:
    /// - Image is sent to Textract
    /// Then:
    /// - The operation completes successfully
    /// - fullText from returned data is not empty
    /// - keyValues from returned data is not empty
    /// - tables from returned data is not empty
    func testIdentifyTextAll() {
        let testBundle = Bundle(for: type(of: self))
        guard let url = testBundle.url(forResource: "testImageTextAll", withExtension: "jpg") else {
            XCTFail("Unable to find image")
            return
        }
        let completeInvoked = expectation(description: "Completed is invoked")

        let operation = Amplify.Predictions.identify(type: .detectText(.all),
                                                     image: url,
                                                     options: PredictionsIdentifyRequest.Options()) { event in
            switch event {
            case .success(let result):
                guard let data = result as? IdentifyDocumentTextResult else {
                    XCTFail("data shouldn't be nil")
                    return
                }
                XCTAssertFalse(data.fullText.isEmpty)
                XCTAssertFalse(data.words.isEmpty)
                XCTAssertEqual(data.words.count, 55)
                XCTAssertFalse(data.rawLineText.isEmpty)
                XCTAssertEqual(data.rawLineText.count, 23)
                XCTAssertFalse(data.identifiedLines.isEmpty)
                XCTAssertEqual(data.identifiedLines.count, 23)
                XCTAssertFalse(data.tables.isEmpty)
                XCTAssertEqual(data.tables.count, 1)
                XCTAssertFalse(data.keyValues.isEmpty)
                XCTAssertEqual(data.keyValues.count, 4)
                completeInvoked.fulfill()
            case .failure(let error):
                XCTFail("Failed with \(error)")
            }
        }

        XCTAssertNotNil(operation)
        waitForExpectations(timeout: networkTimeout)
    }

    /// Given:
    /// - An Image with plain text and form
    /// When:
    /// - Image is sent to Textract
    /// Then:
    /// - The operation completes successfully
    /// - fullText from returned data is not empty
    /// - keyValues from returned data is not empty
    func testIdentifyTextForms() {
        let testBundle = Bundle(for: type(of: self))
        guard let url = testBundle.url(forResource: "testImageTextForms", withExtension: "jpg") else {
            XCTFail("Unable to find image")
            return
        }
        let completeInvoked = expectation(description: "Completed is invoked")

        let operation = Amplify.Predictions.identify(type: .detectText(.form),
                                                     image: url,
                                                     options: PredictionsIdentifyRequest.Options()) { event in
            switch event {
            case .success(let result):
                guard let data = result as? IdentifyDocumentTextResult else {
                    XCTFail("data shouldn't be nil")
                    return
                }
                XCTAssertFalse(data.fullText.isEmpty)
                XCTAssertFalse(data.words.isEmpty)
                XCTAssertEqual(data.words.count, 33)
                XCTAssertFalse(data.rawLineText.isEmpty)
                XCTAssertEqual(data.rawLineText.count, 17)
                XCTAssertFalse(data.identifiedLines.isEmpty)
                XCTAssertEqual(data.identifiedLines.count, 17)
                XCTAssertFalse(data.keyValues.isEmpty)
                XCTAssertEqual(data.keyValues.count, 7)
                completeInvoked.fulfill()
            case .failure(let error):
                XCTFail("Failed with \(error)")
            }
        }

        XCTAssertNotNil(operation)
        waitForExpectations(timeout: networkTimeout)
    }

    /// Given:
    /// - An Image with plain text and table
    /// When:
    /// - Image is sent to Textract
    /// Then:
    /// - The operation completes successfully
    /// - fullText from returned data is not empty
    /// - tables from returned data is not empty
    func testIdentifyTextTables() {
        let testBundle = Bundle(for: type(of: self))
        guard let url = testBundle.url(forResource: "testImageTextWithTables", withExtension: "jpg") else {
            XCTFail("Unable to find image")
            return
        }

        let completeInvoked = expectation(description: "Completed is invoked")

        let operation = Amplify.Predictions.identify(type: .detectText(.table),
                                                     image: url,
                                                     options: PredictionsIdentifyRequest.Options()) { event in
            switch event {
            case .success(let result):
                guard let data = result as? IdentifyDocumentTextResult else {
                    XCTFail("data shouldn't be nil")
                    return
                }
                XCTAssertFalse(data.fullText.isEmpty)
                XCTAssertFalse(data.words.isEmpty)
                XCTAssertEqual(data.words.count, 5)
                XCTAssertFalse(data.rawLineText.isEmpty)
                XCTAssertEqual(data.rawLineText.count, 3)
                XCTAssertFalse(data.identifiedLines.isEmpty)
                XCTAssertEqual(data.identifiedLines.count, 3)
                XCTAssertFalse(data.tables.isEmpty)
                XCTAssertEqual(data.tables.count, 1)
                XCTAssertFalse(data.tables[0].cells.isEmpty)
                XCTAssertEqual(data.tables[0].cells.count, 3)
                XCTAssertEqual(data.tables[0].cells[0].rowIndex, 1)
                XCTAssertEqual(data.tables[0].cells[0].columnIndex, 1)
                XCTAssertEqual(data.tables[0].cells[0].text, "Upper left")
                XCTAssertEqual(data.tables[0].cells[1].rowIndex, 2)
                XCTAssertEqual(data.tables[0].cells[1].columnIndex, 2)
                XCTAssertEqual(data.tables[0].cells[1].text, "Middle")
                XCTAssertEqual(data.tables[0].cells[2].rowIndex, 3)
                XCTAssertEqual(data.tables[0].cells[2].columnIndex, 3)
                XCTAssertEqual(data.tables[0].cells[2].text, "Bottom right")
                completeInvoked.fulfill()
            case .failure(let error):
                XCTFail("Failed with \(error)")
            }
        }

        XCTAssertNotNil(operation)
        waitForExpectations(timeout: networkTimeout)
    }

}
