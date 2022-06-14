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

    override func setUp() async throws {
        let mockConfigurationJSON = """
        {
            "defaultRegion": "us-west-2"
        }
        """.data(using: .utf8)!
        do {
            let clientDelegate = NativeWSTranscribeStreamingClientDelegate()
            let dispatchQueue = DispatchQueue(label: "TranscribeStreamingTests")
            let nativeWebSocketProvider = NativeWebSocketProvider(clientDelegate: clientDelegate,
                                                                  callbackQueue: dispatchQueue)
            let mockConfiguration = try JSONDecoder().decode(PredictionsPluginConfiguration.self,
                                                             from: mockConfigurationJSON)
            predictionsService = AWSPredictionsService(identifier: "",
                                                       awsTranslate: MockTranslateBehavior(),
                                                       awsRekognition: MockRekognitionBehavior(),
                                                       awsTextract: mockTextract,
                                                       awsComprehend: MockComprehendBehavior(),
                                                       awsPolly: MockPollyBehavior(),
                                                       awsTranscribeStreaming: MockTranscribeBehavior(),
                                                       nativeWebSocketProvider: nativeWebSocketProvider,
                                                       transcribeClientDelegate: clientDelegate,
                                                       configuration: mockConfiguration)
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
    func testIdentifyTablesService() {
        let mockResponse: AWSTextractAnalyzeDocumentResponse = AWSTextractAnalyzeDocumentResponse()
        mockResponse.blocks = [AWSTextractBlock]()

        mockTextract.setAnalyzeDocument(result: mockResponse)
        let testBundle = Bundle(for: type(of: self))
        guard let url = testBundle.url(forResource: "testImageText", withExtension: "jpg") else {
            XCTFail("Unable to find image")
            return
        }
        let resultReceived = expectation(description: "Transcription result should be returned")

        predictionsService.detectText(image: url, format: .table) { event in
            switch event {
            case .completed(let result):
                let textResult = result as? IdentifyDocumentTextResult
                let text = IdentifyTextResultTransformers.processText(mockResponse.blocks!)
                XCTAssertEqual(textResult?.identifiedLines.count,
                               text.identifiedLines.count, "Line count should be the same")
                resultReceived.fulfill()
            case .failed(let error):
                XCTFail("Should not produce error: \(error)")
            }
        }

        waitForExpectations(timeout: 1)
    }

    /// Test whether error is correctly propogated for text matches
    ///
    /// - Given: Predictions service with textract behavior
    /// - When:
    ///    - I invoke an invalid request
    /// - Then:
    ///    - I should get back a service error
    ///
    func testIdentifyTablesServiceWithError() {
        let mockError = NSError(domain: AWSTextractErrorDomain,
                                code: AWSTextractErrorType.badDocument.rawValue,
                                userInfo: [:])
        mockTextract.setError(error: mockError)
        let url = URL(fileURLWithPath: "")
        let errorReceived = expectation(description: "Error should be returned")

        predictionsService.detectText(image: url, format: .table) { event in
            switch event {
            case .completed(let result):
                XCTFail("Should not produce result: \(result)")
            case .failed(let error):
                XCTAssertNotNil(error, "Should produce an error")
                errorReceived.fulfill()
            }
        }

        waitForExpectations(timeout: 1)
    }

    /// Test whether error is correctly propogated for text matches with nil response
    ///
    /// - Given: Predictions service with textract behavior
    /// - When:
    ///    - I invoke an invalid request
    /// - Then:
    ///    - I should get back a service error
    ///
    func testIdentifyTablesServiceWithNilResponse() {
        mockTextract.setAnalyzeDocument(result: nil)
        let testBundle = Bundle(for: type(of: self))
        guard let url = testBundle.url(forResource: "testImageText", withExtension: "jpg") else {
            XCTFail("Unable to find image")
            return
        }
        let errorReceived = expectation(description: "Error should be returned")

        predictionsService.detectText(image: url, format: .table) { event in
            switch event {
            case .completed(let result):
                XCTFail("Should not produce result: \(result)")
            case .failed(let error):
                XCTAssertNotNil(error, "Should produce an error")
                errorReceived.fulfill()
            }
        }

        waitForExpectations(timeout: 1)
    }

    /// Test whether we can make a successfull textract call to identify forms
    ///
    /// - Given: Predictions service with textract behavior
    /// - When:
    ///    - I invoke textract api in predictions service
    /// - Then:
    ///    - I should get back a result
    ///
    func testIdentifyFormsService() {
        let mockResponse: AWSTextractAnalyzeDocumentResponse = AWSTextractAnalyzeDocumentResponse()
        mockResponse.blocks = [AWSTextractBlock]()

        mockTextract.setAnalyzeDocument(result: mockResponse)
        let testBundle = Bundle(for: type(of: self))
        guard let url = testBundle.url(forResource: "testImageText", withExtension: "jpg") else {
            XCTFail("Unable to find image")
            return
        }
        let resultReceived = expectation(description: "Transcription result should be returned")

        predictionsService.detectText(image: url, format: .form) { event in
            switch event {
            case .completed(let result):
                let textResult = result as? IdentifyDocumentTextResult
                let text = IdentifyTextResultTransformers.processText(mockResponse.blocks!)
                XCTAssertEqual(textResult?.identifiedLines.count,
                               text.identifiedLines.count, "Line count should be the same")
                resultReceived.fulfill()
            case .failed(let error):
                XCTFail("Should not produce error: \(error)")
            }
        }

        waitForExpectations(timeout: 1)
    }

    /// Test whether error is correctly propogated for document text matches
    ///
    /// - Given: Predictions service with textract behavior
    /// - When:
    ///    - I invoke an invalid request
    /// - Then:
    ///    - I should get back a service error
    ///
    func testIdentifyFormsServiceWithError() {
        let mockError = NSError(domain: AWSTextractErrorDomain,
                                code: AWSTextractErrorType.badDocument.rawValue,
                                userInfo: [:])
        mockTextract.setError(error: mockError)
        let url = URL(fileURLWithPath: "")
        let errorReceived = expectation(description: "Error should be returned")

        predictionsService.detectText(image: url, format: .form) { event in
            switch event {
            case .completed(let result):
                XCTFail("Should not produce result: \(result)")
            case .failed(let error):
                XCTAssertNotNil(error, "Should produce an error")
                errorReceived.fulfill()
            }
        }

        waitForExpectations(timeout: 1)
    }

    /// Test whether error is correctly propogated for text matches with nil response
    ///
    /// - Given: Predictions service with textract behavior
    /// - When:
    ///    - I invoke a normal request
    /// - Then:
    ///    - I should get back a service error because response is nil
    ///
    func testIdentifyFormsServiceWithNilResponse() {
        mockTextract.setAnalyzeDocument(result: nil)
        let testBundle = Bundle(for: type(of: self))
        guard let url = testBundle.url(forResource: "testImageText", withExtension: "jpg") else {
            XCTFail("Unable to find image")
            return
        }
        let errorReceived = expectation(description: "Error should be returned")

        predictionsService.detectText(image: url, format: .form) { event in
            switch event {
            case .completed(let result):
                XCTFail("Should not produce result: \(result)")
            case .failed(let error):
                XCTAssertNotNil(error, "Should produce an error")
                errorReceived.fulfill()
            }
        }

        waitForExpectations(timeout: 1)
    }

    /// Test whether we can make a successfull textract call to identify forms and tables
    ///
    /// - Given: Predictions service with textract behavior
    /// - When:
    ///    - I invoke textract api in predictions service
    /// - Then:
    ///    - I should get back a result
    ///
    func testIdentifyAllTextService() {
        let mockResponse: AWSTextractAnalyzeDocumentResponse = AWSTextractAnalyzeDocumentResponse()
        mockResponse.blocks = [AWSTextractBlock]()

        mockTextract.setAnalyzeDocument(result: mockResponse)
        let testBundle = Bundle(for: type(of: self))
        guard let url = testBundle.url(forResource: "testImageText", withExtension: "jpg") else {
            XCTFail("Unable to find image")
            return
        }
        let resultReceived = expectation(description: "Transcription result should be returned")

        predictionsService.detectText(image: url, format: .all) { event in
            switch event {
            case .completed(let result):
                let textResult = result as? IdentifyDocumentTextResult
                let text = IdentifyTextResultTransformers.processText(mockResponse.blocks!)
                XCTAssertEqual(textResult?.identifiedLines.count,
                               text.identifiedLines.count, "Line count should be the same")
                resultReceived.fulfill()
            case .failed(let error):
                XCTFail("Should not produce error: \(error)")
            }
        }

        waitForExpectations(timeout: 1)
    }

    /// Test whether error is correctly propogated for .all document text matches
    ///
    /// - Given: Predictions service with textract behavior
    /// - When:
    ///    - I invoke an invalid request
    /// - Then:
    ///    - I should get back a service error
    ///
    func testIdentifyAllTextServiceWithError() {
        let mockError = NSError(domain: AWSTextractErrorDomain,
                                code: AWSTextractErrorType.badDocument.rawValue,
                                userInfo: [:])
        mockTextract.setError(error: mockError)
        let url = URL(fileURLWithPath: "")
        let errorReceived = expectation(description: "Error should be returned")

        predictionsService.detectText(image: url, format: .all) { event in
            switch event {
            case .completed(let result):
                XCTFail("Should not produce result: \(result)")
            case .failed(let error):
                XCTAssertNotNil(error, "Should produce an error")
                errorReceived.fulfill()
            }
        }

        waitForExpectations(timeout: 1)
    }

    /// Test whether error is correctly propogated for text matches with nil response
    ///
    /// - Given: Predictions service with textract behavior
    /// - When:
    ///    - I invoke a normal request
    /// - Then:
    ///    - I should get back a service error because response is nil
    ///
    func testIdentifyAllTextServiceWithNilResponse() {
        mockTextract.setAnalyzeDocument(result: nil)
        let testBundle = Bundle(for: type(of: self))
        guard let url = testBundle.url(forResource: "testImageText", withExtension: "jpg") else {
            XCTFail("Unable to find image")
            return
        }
        let errorReceived = expectation(description: "Error should be returned")

        predictionsService.detectText(image: url, format: .all) { event in
            switch event {
            case .completed(let result):
                XCTFail("Should not produce result: \(result)")
            case .failed(let error):
                XCTAssertNotNil(error, "Should produce an error")
                errorReceived.fulfill()
            }
        }

        waitForExpectations(timeout: 1)
    }
}
