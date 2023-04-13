//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
import AWSTranslate
import Amplify
@testable import AWSPredictionsPlugin

//class PredictionsServiceTranslateTests: XCTestCase {
//
//    var predictionsService: AWSPredictionsService!
//    let mockTranslate = MockTranslateBehavior()
//
//    override func setUp() {
//        let mockConfigurationJSON = """
//        {
//            "defaultRegion": "us_east_1"
//        }
//        """.data(using: .utf8)!
//        do {
//            let clientDelegate = NativeWSTranscribeStreamingClientDelegate()
//            let dispatchQueue = DispatchQueue(label: "TranscribeStreamingTests")
//            let nativeWebSocketProvider = NativeWebSocketProvider(clientDelegate: clientDelegate,
//                                                                  callbackQueue: dispatchQueue)
//            let mockConfiguration = try JSONDecoder().decode(PredictionsPluginConfiguration.self,
//                                                             from: mockConfigurationJSON)
//            predictionsService = AWSPredictionsService(identifier: "",
//                                                       awsTranslate: mockTranslate,
//                                                       awsRekognition: MockRekognitionBehavior(),
//                                                       awsTextract: MockTextractBehavior(),
//                                                       awsComprehend: MockComprehendBehavior(),
//                                                       awsPolly: MockPollyBehavior(),
//                                                       awsTranscribeStreaming: MockTranscribeBehavior(),
//                                                       nativeWebSocketProvider: nativeWebSocketProvider,
//                                                       transcribeClientDelegate: clientDelegate,
//                                                       configuration: mockConfiguration)
//        } catch {
//            XCTFail("Initialization of the test failed")
//        }
//    }
//
//    /// Test whether we can make a successful translate call
//    ///
//    /// - Given: Predictions service with translate behavior
//    /// - When:
//    ///    - I invoke translate api in predictions service
//    /// - Then:
//    ///    - I should get back a result
//    ///
//    func testTranslateService() {
//        let mockResponse = AWSTranslateTranslateTextResponse()!
//        mockResponse.translatedText = "translated text here"
//        mockTranslate.setResult(result: mockResponse)
//
//        let resultReceived = expectation(description: "Transcription result should be returned")
//
//        predictionsService.translateText(text: "Hello there",
//                                         language: .english,
//                                         targetLanguage: .italian) { event in
//            switch event {
//            case .completed(let result):
//                XCTAssertEqual(result.text,
//                               mockResponse.translatedText,
//                               "Translated text should be same")
//                resultReceived.fulfill()
//            case .failed(let error):
//                XCTFail("Should not produce error: \(error)")
//            }
//        }
//
//        waitForExpectations(timeout: 1)
//    }
//
//    /// Test whether error is correctly propogated
//    ///
//    /// - Given: Predictions service with translate behavior
//    /// - When:
//    ///    - I invoke an invalid request
//    /// - Then:
//    ///    - I should get back a service error
//    ///
//    func testTranslateServiceWithError() {
//        let mockError = NSError(domain: AWSTranslateErrorDomain,
//                                code: AWSTranslateErrorType.invalidRequest.rawValue,
//                                userInfo: [:])
//        mockTranslate.setError(error: mockError)
//
//        let errorReceived = expectation(description: "Error should be returned")
//
//        predictionsService.translateText(text: "",
//                                         language: .english,
//                                         targetLanguage: .italian) { event in
//            switch event {
//            case .completed(let result):
//                XCTFail("Should not produce result: \(result)")
//            case .failed(let error):
//                XCTAssertNotNil(error, "Should produce an error")
//                errorReceived.fulfill()
//            }
//        }
//
//        waitForExpectations(timeout: 1)
//    }
//
//    /// Test if language from configuration is picked up
//    ///
//    /// - Given: Predictions service with translate behavior. And source, target lanugage
//    /// is set in configuration
//    /// - When:
//    ///    - Invoke translate text
//    /// - Then:
//    ///    - I should get a successful result
//    ///
//    func testLanguageFromConfiguration() {
//        let mockConfigurationJSON = """
//        {
//            "defaultRegion": "us-east-1",
//            "convert": {
//                "translateText": {
//                    "region": "us-east-1",
//                    "sourceLang": "en",
//                    "targetLang": "it"
//                }
//            }
//        }
//        """.data(using: .utf8)!
//        do {
//            let clientDelegate = NativeWSTranscribeStreamingClientDelegate()
//            let dispatchQueue = DispatchQueue(label: "TranscribeStreamingTests")
//            let nativeWebSocketProvider = NativeWebSocketProvider(clientDelegate: clientDelegate,
//                                                                  callbackQueue: dispatchQueue)
//            let mockConfiguration = try JSONDecoder().decode(PredictionsPluginConfiguration.self,
//                                                             from: mockConfigurationJSON)
//            predictionsService = AWSPredictionsService(identifier: "",
//                                                       awsTranslate: mockTranslate,
//                                                       awsRekognition: MockRekognitionBehavior(),
//                                                       awsTextract: MockTextractBehavior(),
//                                                       awsComprehend: MockComprehendBehavior(),
//                                                       awsPolly: MockPollyBehavior(),
//                                                       awsTranscribeStreaming: MockTranscribeBehavior(),
//                                                       nativeWebSocketProvider: nativeWebSocketProvider,
//                                                       transcribeClientDelegate: clientDelegate,
//                                                       configuration: mockConfiguration)
//        } catch {
//            XCTFail("Initialization of the text failed. \(error)")
//        }
//
//        let mockResponse = AWSTranslateTranslateTextResponse()!
//        mockResponse.translatedText = "translated text here"
//        mockTranslate.setResult(result: mockResponse)
//
//        let resultReceived = expectation(description: "Transcription result should be returned")
//
//        predictionsService.translateText(text: "Hello there",
//                                         language: nil,
//                                         targetLanguage: nil) { event in
//            switch event {
//            case .completed(let result):
//                XCTAssertEqual(result.text,
//                               mockResponse.translatedText,
//                               "Translated text should be same")
//                resultReceived.fulfill()
//            case .failed(let error):
//                XCTFail("Should not produce error: \(error)")
//            }
//        }
//
//        waitForExpectations(timeout: 1)
//    }
//
//    /// Test if the source language is nil error is thrown
//    ///
//    /// - Given: Predictions service with translate behavior
//    /// - When:
//    ///    - I invoke translate text with source language is nil
//    /// - Then:
//    ///    - I should get back an error
//    ///
//    func testNilSourceLanguageError() {
//        let mockResponse = AWSTranslateTranslateTextResponse()!
//        mockResponse.translatedText = "translated text here"
//        mockTranslate.setResult(result: mockResponse)
//
//        let errorReceived = expectation(description: "Error should be returned")
//
//        predictionsService.translateText(text: "",
//                                         language: nil,
//                                         targetLanguage: .italian) { event in
//            switch event {
//            case .completed(let result):
//                XCTFail("Should not produce result: \(result)")
//            case .failed(let error):
//                XCTAssertNotNil(error, "Should produce an error")
//                errorReceived.fulfill()
//            }
//        }
//
//        waitForExpectations(timeout: 1)
//    }
//
//    /// Test if the target is nil and configuration is not set
//    ///
//    /// - Given: Predictions service with translate behavior
//    /// - When:
//    ///    - I invoke translate text with target language nil
//    /// - Then:
//    ///    - I should get back an error
//    ///
//    func testNilTargetLanguageError() {
//        let mockResponse = AWSTranslateTranslateTextResponse()!
//        mockResponse.translatedText = "translated text here"
//        mockTranslate.setResult(result: mockResponse)
//
//        let errorReceived = expectation(description: "Error should be returned")
//
//        predictionsService.translateText(text: "",
//                                         language: .english,
//                                         targetLanguage: nil) { event in
//            switch event {
//            case .completed(let result):
//                XCTFail("Should not produce result: \(result)")
//            case .failed(let error):
//                XCTAssertNotNil(error, "Should produce an error")
//                errorReceived.fulfill()
//            }
//        }
//
//        waitForExpectations(timeout: 1)
//    }
//
//    /// Test if the service returns nil, we get an error back
//    ///
//    /// - Given: Predictions service with translate behavior
//    /// - When:
//    ///    - Invoke translate text and if service return nil result
//    /// - Then:
//    ///    - I should get an error back
//    ///
//    func testNilResult() {
//        mockTranslate.setResult(result: nil)
//
//        let errorReceived = expectation(description: "Error should be returned")
//
//        predictionsService.translateText(text: "",
//                                         language: .english,
//                                         targetLanguage: .spanish) { event in
//            switch event {
//            case .completed(let result):
//                XCTFail("Should not produce result: \(result)")
//            case .failed(let error):
//                XCTAssertNotNil(error, "Should produce an error")
//                errorReceived.fulfill()
//            }
//        }
//
//        waitForExpectations(timeout: 1)
//    }
//
//    /// Test if the service returns nil for translated text, we get an error back
//    ///
//    /// - Given: Predictions service with translate behavior
//    /// - When:
//    ///    - Invoke translate text and if service return nil result
//    /// - Then:
//    ///    - I should get an error back
//    ///
//    func testNilTranslatedTextResult() {
//        let mockResponse = AWSTranslateTranslateTextResponse()!
//        mockTranslate.setResult(result: mockResponse)
//
//        let errorReceived = expectation(description: "Error should be returned")
//
//        predictionsService.translateText(text: "",
//                                         language: .english,
//                                         targetLanguage: .spanish) { event in
//            switch event {
//            case .completed(let result):
//                XCTFail("Should not produce result: \(result)")
//            case .failed(let error):
//                XCTAssertNotNil(error, "Should produce an error")
//                errorReceived.fulfill()
//            }
//        }
//
//        waitForExpectations(timeout: 1)
//    }
//
//    /// Test if the target language is set
//    ///
//    /// - Given: Predictions service with translate behavior
//    /// - When:
//    ///    - Invoke translate text
//    /// - Then:
//    ///    - The target language should be set
//    ///
//    func testTargetLanguageTranslateService() {
//        let mockResponse = AWSTranslateTranslateTextResponse()!
//        mockResponse.translatedText = "translated text here"
//        mockTranslate.setResult(result: mockResponse)
//
//        let resultReceived = expectation(description: "Transcription result should be returned")
//
//        predictionsService.translateText(text: "Hello there",
//                                         language: .english,
//                                         targetLanguage: .malayalam) { event in
//            switch event {
//            case .completed(let result):
//                XCTAssertEqual(result.text,
//                               mockResponse.translatedText,
//                               "Translated text should be same")
//                XCTAssertEqual(result.targetLanguage, .malayalam)
//                resultReceived.fulfill()
//            case .failed(let error):
//                XCTFail("Should not produce error: \(error)")
//            }
//        }
//
//        waitForExpectations(timeout: 1)
//    }
//}
