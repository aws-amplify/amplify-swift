//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
import AWSTextract
import CoreML
import Amplify
import Foundation
@testable import AWSPredictionsPlugin

class PredictionsServiceTextractTests: XCTestCase {
    var predictionsService: AWSPredictionsService!
    let mockTextract = MockTextractBehavior()

    let mockError = NSError(
        domain: "aws.rekognition.errordomain",
        code: 42,
        userInfo: [:]
    )

    func url(_ resource: String) throws -> URL {
        let testBundle = Bundle.module
        return try XCTUnwrap(
            testBundle.url(forResource: resource, withExtension: "jpg", subdirectory: "TestImages"),
            "Unable to find resource: \(resource)"
        )
    }

    override func setUp() {
        let mockConfigurationJSON = """
        {
            "defaultRegion": "us-west-2"
        }
        """
        do {
            let mockConfiguration = try JSONDecoder().decode(
                PredictionsPluginConfiguration.self,
                from: Data(mockConfigurationJSON.utf8)
            )

            predictionsService = AWSPredictionsService(
                identifier: "",
                awsTranslate: MockTranslateBehavior(),
                awsRekognition: MockRekognitionBehavior(),
                awsTextract: mockTextract,
                awsComprehend: MockComprehendBehavior(),
                awsPolly: MockPollyBehavior(),
                awsTranscribeStreaming: MockTranscribeBehavior(),
                configuration: mockConfiguration
            )
        } catch {
            XCTFail("Initialization of the text failed")
        }
    }

    /// Test whether we can make a successfull textract call to identify tables
    ///
    /// - Given: Predictions service with textract behavior
    /// - When:
    ///    - I invoke textract api in predictions service
    /// - Then:
    ///    - I should get back a result
    ///
    func testIdentifyTablesService() async throws {
        let mockResponse = AnalyzeDocumentOutputResponse(blocks: [])
        mockTextract.analyzeDocumentResult = { _ in mockResponse }
        let url = try url("testImageText")

        let result = try await predictionsService.detectDocumentText(image: url, format: .table)
        let text = IdentifyTextResultTransformers.processText(mockResponse.blocks!)
        XCTAssertEqual(
            result.identifiedLines.count,
            text.identifiedLines.count,
            "Line count should be the same"
        )
    }

    /// Test whether error is correctly propogated for text matches
    ///
    /// - Given: Predictions service with textract behavior
    /// - When:
    ///    - I invoke an invalid request
    /// - Then:
    ///    - I should get back a service error
    ///
    func testIdentifyTablesServiceWithError() async throws {
        mockTextract.analyzeDocumentResult = { _ in throw self.mockError }
        let url = URL(fileURLWithPath: "")

        do {
            let result = try await predictionsService.detectDocumentText(image: url, format: .table)
            XCTFail("Should not produce result: \(result)")
        } catch {
            XCTAssertNotNil(error, "Should produce an error")
        }
    }



    /// Test whether we can make a successfull textract call to identify forms
    ///
    /// - Given: Predictions service with textract behavior
    /// - When:
    ///    - I invoke textract api in predictions service
    /// - Then:
    ///    - I should get back a result
    ///
    func testIdentifyFormsService() async throws {
        let mockResponse = AnalyzeDocumentOutputResponse(blocks: [])
        mockTextract.analyzeDocumentResult = { _ in mockResponse }
        let url = try url("testImageText")

        let result = try await predictionsService.detectDocumentText(image: url, format: .form)
        let text = IdentifyTextResultTransformers.processText(mockResponse.blocks!)
        XCTAssertEqual(
            result.identifiedLines.count,
            text.identifiedLines.count,
            "Line count should be the same"
        )
    }

    /// Test whether error is correctly propogated for document text matches
    ///
    /// - Given: Predictions service with textract behavior
    /// - When:
    ///    - I invoke an invalid request
    /// - Then:
    ///    - I should get back a service error
    ///
    func testIdentifyFormsServiceWithError() async throws {
        mockTextract.analyzeDocumentResult = { _ in throw self.mockError }
        let url = URL(fileURLWithPath: "")

        do {
            let result = try await predictionsService.detectDocumentText(image: url, format: .form)
            XCTFail("Should not produce result: \(result)")
        } catch {
            XCTAssertNotNil(error, "Should produce an error")
        }
    }



    /// Test whether we can make a successfull textract call to identify forms and tables
    ///
    /// - Given: Predictions service with textract behavior
    /// - When:
    ///    - I invoke textract api in predictions service
    /// - Then:
    ///    - I should get back a result
    ///
    func testIdentifyAllTextService() async throws {
        let mockResponse = AnalyzeDocumentOutputResponse(blocks: [])
        mockTextract.analyzeDocumentResult = { _ in mockResponse }
        let url = try url("testImageText")

        let result = try await predictionsService.detectDocumentText(image: url, format: .all)
        let text = IdentifyTextResultTransformers.processText(mockResponse.blocks!)
        XCTAssertEqual(
            result.identifiedLines.count,
            text.identifiedLines.count,
            "Line count should be the same"
        )
    }

    /// Test whether error is correctly propogated for .all document text matches
    ///
    /// - Given: Predictions service with textract behavior
    /// - When:
    ///    - I invoke an invalid request
    /// - Then:
    ///    - I should get back a service error
    ///
    func testIdentifyAllTextServiceWithError() async throws {
        mockTextract.analyzeDocumentResult = { _ in throw self.mockError }
        let url = URL(fileURLWithPath: "")

        do {
            let result = try await predictionsService.detectDocumentText(image: url, format: .all)
            XCTFail("Should not produce result: \(result)")
        } catch {
            XCTAssertNotNil(error, "Should produce an error")
        }
    }
}


/// Test whether error is correctly propogated for text matches with nil response
///
/// - Given: Predictions service with textract behavior
/// - When:
///    - I invoke an invalid request
/// - Then:
///    - I should get back a service error
///
//func testIdentifyTablesServiceWithNilResponse() {
//    mockTextract.setAnalyzeDocument(result: nil)
//    let testBundle = Bundle(for: type(of: self))
//    guard let url = testBundle.url(forResource: "testImageText", withExtension: "jpg") else {
//        XCTFail("Unable to find image")
//        return
//    }
//    let errorReceived = expectation(description: "Error should be returned")
//
//    predictionsService.detectText(image: url, format: .table) { event in
//        switch event {
//        case .completed(let result):
//            XCTFail("Should not produce result: \(result)")
//        case .failed(let error):
//            XCTAssertNotNil(error, "Should produce an error")
//            errorReceived.fulfill()
//        }
//    }
//
//    waitForExpectations(timeout: 1)
//}
/// Test whether error is correctly propogated for text matches with nil response
///
/// - Given: Predictions service with textract behavior
/// - When:
///    - I invoke a normal request
/// - Then:
///    - I should get back a service error because response is nil
///
//func testIdentifyFormsServiceWithNilResponse() {
//    mockTextract.setAnalyzeDocument(result: nil)
//    let testBundle = Bundle(for: type(of: self))
//    guard let url = testBundle.url(forResource: "testImageText", withExtension: "jpg") else {
//        XCTFail("Unable to find image")
//        return
//    }
//    let errorReceived = expectation(description: "Error should be returned")
//
//    predictionsService.detectText(image: url, format: .form) { event in
//        switch event {
//        case .completed(let result):
//            XCTFail("Should not produce result: \(result)")
//        case .failed(let error):
//            XCTAssertNotNil(error, "Should produce an error")
//            errorReceived.fulfill()
//        }
//    }
//
//    waitForExpectations(timeout: 1)
//}
/// Test whether error is correctly propogated for text matches with nil response
///
/// - Given: Predictions service with textract behavior
/// - When:
///    - I invoke a normal request
/// - Then:
///    - I should get back a service error because response is nil
///
//func testIdentifyAllTextServiceWithNilResponse() {
//    mockTextract.setAnalyzeDocument(result: nil)
//    let testBundle = Bundle(for: type(of: self))
//    guard let url = testBundle.url(forResource: "testImageText", withExtension: "jpg") else {
//        XCTFail("Unable to find image")
//        return
//    }
//    let errorReceived = expectation(description: "Error should be returned")
//
//    predictionsService.detectText(image: url, format: .all) { event in
//        switch event {
//        case .completed(let result):
//            XCTFail("Should not produce result: \(result)")
//        case .failed(let error):
//            XCTAssertNotNil(error, "Should produce an error")
//            errorReceived.fulfill()
//        }
//    }
//
//    waitForExpectations(timeout: 1)
//}
