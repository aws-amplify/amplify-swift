//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import UIKit
@testable import Amplify
@testable import AWSPredictionsPlugin
@testable import AWSRekognition
import XCTest

class IdentifyBasicIntegrationTests: AWSPredictionsPluginTestBase {

    private func imageURL(for resource: String) throws -> URL {
        try XCTUnwrap(
            Bundle(for: type(of: self))
                .url(forResource: resource, withExtension: "jpg")
        )
    }

    /// Given: An Image
    /// When: Image is sent to Rekognition
    /// Then: The operation completes successfully
    func testIdentifyLabels() async throws {
        let url = try imageURL(for: "testImageLabels")

        let result = try await Amplify.Predictions.identify(
            .labels(type: .labels),
            in: url
        )
        print(#function, result)
        XCTAssertNotNil(result)
    }

    func testIdentifyModerationLabels() async throws {
        let url = try imageURL(for: "testImageLabels")
        let result = try await Amplify.Predictions.identify(
            .labels(type: .moderation),
            in: url,
            options: .init()
        )
        print(#function, result)
        XCTAssertNotNil(result)
    }

    func testIdentifyAllLabels() async throws {
        let url = try imageURL(for: "testImageLabels")
        let result = try await Amplify.Predictions.identify(
            .labels(type: .all),
            in: url,
            options: .init()
        )
        print(#function, result)
        XCTAssertNotNil(result)
    }

    func testIdentifyCelebrities() async throws {
        let url = try imageURL(for: "testImageCeleb")
        let result = try await Amplify.Predictions.identify(
            .celebrities,
            in: url,
            options: .init()
        )
        print(#function, result)
        XCTAssertNotNil(result)
    }

    func testIdentifyEntityMatches() async throws {
        let url = try imageURL(for: "testImageEntities")
        let result = try await Amplify.Predictions.identify(
            .entities,
            in: url,
            options: .init()
        )
        print(#function, result)
        XCTAssertNotNil(result)
    }

    func testIdentifyEntities() async throws {
        let url = try imageURL(for: "testImageEntities")
        let result = try await Amplify.Predictions.identify(
            .entities,
            in: url,
            options: .init()
        )
        print(#function, result)
        XCTAssertNotNil(result)
    }

    func testIdentifyTextPlain() async throws {
        let url = try imageURL(for: "testImageText")
        let result = try await Amplify.Predictions.identify(
            .textInDocument(textFormatType: .plain),
            in: url,
            options: .init()
        )
        print(#function, result)
        XCTAssertNotNil(result)
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
    func testIdentifyTextAll() async throws {
        let url = try imageURL(for: "testImageTextAll")
        let result = try await Amplify.Predictions.identify(
            .textInDocument(textFormatType: .all),
            in: url,
            options: .init()
        )

        XCTAssertNotNil(result)
        XCTAssertFalse(result.fullText.isEmpty)
        XCTAssertFalse(result.words.isEmpty)
        XCTAssertEqual(result.words.count, 55)
        XCTAssertFalse(result.rawLineText.isEmpty)
        XCTAssertEqual(result.rawLineText.count, 23)
        XCTAssertFalse(result.identifiedLines.isEmpty)
        XCTAssertEqual(result.identifiedLines.count, 23)
        XCTAssertFalse(result.tables.isEmpty)
        XCTAssertEqual(result.tables.count, 1)
        XCTAssertFalse(result.keyValues.isEmpty)
        XCTAssertEqual(result.keyValues.count, 4)

    }

    /// Given:
    /// - An Image with plain text and form
    /// When:
    /// - Image is sent to Textract
    /// Then:
    /// - The operation completes successfully
    /// - fullText from returned data is not empty
    /// - keyValues from returned data is not empty
    func testIdentifyTextForms() async throws {
        let url = try imageURL(for: "testImageTextForms")
        let result = try await Amplify.Predictions.identify(
            .textInDocument(textFormatType: .form),
            in: url,
            options: .init()
        )

        XCTAssertNotNil(result)
        XCTAssertFalse(result.fullText.isEmpty)
        XCTAssertFalse(result.words.isEmpty)
        XCTAssertEqual(result.words.count, 30)
        XCTAssertFalse(result.rawLineText.isEmpty)
        XCTAssertEqual(result.rawLineText.count, 17)
        XCTAssertFalse(result.identifiedLines.isEmpty)
        XCTAssertEqual(result.identifiedLines.count, 17)
        XCTAssertFalse(result.keyValues.isEmpty)
        XCTAssertEqual(result.keyValues.count, 7)
    }

    /// Given:
    /// - An Image with plain text and table
    /// When:
    /// - Image is sent to Textract
    /// Then:
    /// - The operation completes successfully
    /// - fullText from returned data is not empty
    /// - tables from returned data is not empty
    func testIdentifyTextTables() async throws {
        let url = try imageURL(for: "testImageTextWithTables")

        let result = try await Amplify.Predictions.identify(
            .textInDocument(textFormatType: .table),
            in: url,
            options: PredictionsIdentifyRequest.Options()
        )

        XCTAssertNotNil(result)
        XCTAssertFalse(result.fullText.isEmpty)
        XCTAssertFalse(result.words.isEmpty)
        XCTAssertEqual(result.words.count, 5)
        XCTAssertFalse(result.rawLineText.isEmpty)
        XCTAssertEqual(result.rawLineText.count, 3)
        XCTAssertFalse(result.identifiedLines.isEmpty)
        XCTAssertEqual(result.identifiedLines.count, 3)
        XCTAssertFalse(result.tables.isEmpty)
        XCTAssertEqual(result.tables.count, 1)
        XCTAssertFalse(result.tables[0].cells.isEmpty)
        XCTAssertEqual(result.tables[0].cells.count, 3)
        XCTAssertEqual(result.tables[0].cells[0].rowIndex, 1)
        XCTAssertEqual(result.tables[0].cells[0].columnIndex, 1)
        XCTAssertEqual(result.tables[0].cells[0].text, "Upper left")
        XCTAssertEqual(result.tables[0].cells[1].rowIndex, 2)
        XCTAssertEqual(result.tables[0].cells[1].columnIndex, 2)
        XCTAssertEqual(result.tables[0].cells[1].text, "Middle")
        XCTAssertEqual(result.tables[0].cells[2].rowIndex, 3)
        XCTAssertEqual(result.tables[0].cells[2].columnIndex, 3)
        XCTAssertEqual(result.tables[0].cells[2].text, "Bottom right")

    }

}
