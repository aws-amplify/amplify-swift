//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
import AWSTranscribeStreaming
import Amplify
@testable import AWSPredictionsPlugin

//class PredictionsServiceTranscribeTests: XCTestCase {
//
//    var predictionsService: AWSPredictionsService!
//    let mockTranscribe = MockTranscribeBehavior()
//    var audioFile: URL!
//
//    override func setUp() {
//        let mockConfigurationJSON = """
//        {
//            "defaultRegion": "us_east_1"
//        }
//        """.data(using: .utf8)!
//
//        do {
//            let mockConfiguration = try JSONDecoder().decode(
//                PredictionsPluginConfiguration.self,
//                from: mockConfigurationJSON
//            )
//
//            predictionsService = AWSPredictionsService(
//                identifier: "",
//                awsTranslate: MockTranslateBehavior(),
//                awsRekognition: MockRekognitionBehavior(),
//                awsTextract: mockTextract,
//                awsComprehend: MockComprehendBehavior(),
//                awsPolly: MockPollyBehavior(),
//                configuration: mockConfiguration
//            )
//
//
//            AWSPredictionsService(identifier: "",
//                                                       awsTranslate: MockTranslateBehavior(),
//                                                       awsRekognition: MockRekognitionBehavior(),
//                                                       awsTextract: MockTextractBehavior(),
//                                                       awsComprehend: MockComprehendBehavior(),
//                                                       awsPolly: MockPollyBehavior(),
//                                                       awsTranscribeStreaming: mockTranscribe,
//                                                       nativeWebSocketProvider: nativeWebSocketProvider,
//                                                       transcribeClientDelegate: clientDelegate,
//                                                       configuration: mockConfiguration)
//
//            mockTranscribe.setDelegate(delegate: clientDelegate, callbackQueue: dispatchQueue)
//
//            let testBundle = Bundle(for: type(of: self))
//            guard let url = testBundle.url(forResource: "audio", withExtension: "wav") else {
//                return
//            }
//            audioFile = url
//        } catch {
//            XCTFail("Initialization of the test failed")
//        }
//    }
//
//    func createMockTranscribeResponse() -> AWSTranscribeStreamingTranscriptResultStream {
//        let mockResponse = AWSTranscribeStreamingTranscriptResultStream()!
//        let transcriptEvent = AWSTranscribeStreamingTranscriptEvent()!
//        let str = "This is a test"
//        let results = AWSTranscribeStreamingTranscript()!
//        let resultStream = AWSTranscribeStreamingResult()!
//        let alternative = AWSTranscribeStreamingAlternative()!
//        alternative.transcript = str
//        resultStream.isPartial = false
//        resultStream.alternatives = [alternative]
//        results.results = [resultStream]
//        transcriptEvent.transcript = results
//        mockResponse.transcriptEvent = transcriptEvent
//        return mockResponse
//    }
//
//    /// Test whether we can make a successful transcribe call
//    ///
//    /// - Given: Predictions service with transcribe behavior
//    /// - When:
//    ///    - I invoke transcribe api in predictions service
//    /// - Then:
//    ///    - I should get back a result
//    ///
//    func testTranscribeService() {
//        let mockResponse = createMockTranscribeResponse()
//
//        mockTranscribe.setConnectionResult(result: AWSTranscribeStreamingClientConnectionStatus.connected, error: nil)
//        mockTranscribe.sendEndFrameExpection = expectation(description: "Sent end frame")
//        mockTranscribe.setResult(result: mockResponse)
//
//        let expectedTranscription = "This is a test"
//        let resultReceived = expectation(description: "Transcription result should be returned")
//
//        predictionsService.transcribe(speechToText: audioFile, language: .usEnglish) { event in
//            switch event {
//            case .completed(let result):
//                XCTAssertEqual(result.transcription, expectedTranscription, "transcribed text should be the same")
//                resultReceived.fulfill()
//            case .failed(let error):
//                XCTFail("Should not produce error: \(error)")
//            }
//        }
//
//        waitForExpectations(timeout: 1)
//
//    }
//
//    /// Test whether error is correctly propogated
//    ///
//    /// - Given: Predictions service with transcribe behavior
//    /// - When:
//    ///    - I invoke an invalid request
//    /// - Then:
//    ///    - I should get back a service error
//    ///
//    func testTranscribeServiceWithError() {
//        let mockError = NSError(domain: AWSTranscribeStreamingErrorDomain,
//                                code: AWSTranscribeStreamingErrorType.badRequest.rawValue,
//                                userInfo: [:])
//        mockTranscribe.setError(error: mockError)
//
//        let errorReceived = expectation(description: "Error should be returned")
//
//        predictionsService.transcribe(speechToText: audioFile, language: .usEnglish) { event in
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
//    /// Test whether error is correctly propogated
//    ///
//    /// - Given: Predictions service with transcribe behavior
//    /// - When:
//    ///    - I invoke an invalid request with Unreachable host
//    /// - Then:
//    ///    - I should get back a connection error
//    ///
//    func testTranscribeServiceWithCannotFindHostError() {
//        let urlError = URLError(.cannotFindHost)
//        mockTranscribe.setConnectionResult(result: AWSTranscribeStreamingClientConnectionStatus.closed, error: urlError)
//
//        let errorReceived = expectation(description: "Error should be returned")
//
//        predictionsService.transcribe(speechToText: audioFile, language: .usEnglish) { event in
//            switch event {
//            case .completed(let result):
//                XCTFail("Should not produce result: \(result)")
//            case .failed(let error):
//                guard case .network = error else {
//                    XCTFail("Should produce an network error instead of \(error)")
//                    return
//                }
//                errorReceived.fulfill()
//            }
//        }
//
//        waitForExpectations(timeout: 1)
//    }
//
//    /// Test if language from configuration is picked up
//    ///
//    /// - Given: Predictions service with transcribe behavior. And language is set in config
//    /// - When:
//    ///    - Invoke transcribe
//    /// - Then:
//    ///    - I should get a successful result
//    ///
//    func testLanguageFromConfiguration() {
//        let mockConfigurationJSON = """
//            {
//                "defaultRegion": "us-east-1",
//                "convert": {
//                    "transcription": {
//                        "region": "us-east-1",
//                        "language": "en-US"
//                    }
//                }
//            }
//            """.data(using: .utf8)!
//        do {
//            let clientDelegate = NativeWSTranscribeStreamingClientDelegate()
//            let dispatchQueue = DispatchQueue(label: "TranscribeStreamingTests")
//            let nativeWebSocketProvider = NativeWebSocketProvider(clientDelegate: clientDelegate,
//                                                                  callbackQueue: dispatchQueue)
//            let mockConfiguration = try JSONDecoder().decode(PredictionsPluginConfiguration.self,
//                                                             from: mockConfigurationJSON)
//            predictionsService = AWSPredictionsService(identifier: "",
//                                                       awsTranslate: MockTranslateBehavior(),
//                                                       awsRekognition: MockRekognitionBehavior(),
//                                                       awsTextract: MockTextractBehavior(),
//                                                       awsComprehend: MockComprehendBehavior(),
//                                                       awsPolly: MockPollyBehavior(),
//                                                       awsTranscribeStreaming: mockTranscribe,
//                                                       nativeWebSocketProvider: nativeWebSocketProvider,
//                                                       transcribeClientDelegate: clientDelegate,
//                                                       configuration: mockConfiguration)
//
//            mockTranscribe.setDelegate(delegate: clientDelegate, callbackQueue: dispatchQueue)
//        } catch {
//            XCTFail("Initialization of the service failed. \(error)")
//        }
//
//        let mockResponse = createMockTranscribeResponse()
//        mockTranscribe.setResult(result: mockResponse)
//        let expectedTranscription = "This is a test"
//        let resultReceived = expectation(description: "Transcription result should be returned")
//
//        predictionsService.transcribe(speechToText: audioFile, language: nil) {event in
//            switch event {
//            case .completed(let result):
//                XCTAssertEqual(result.transcription, expectedTranscription, "Transcribed text should be the same")
//                resultReceived.fulfill()
//            case .failed(let error):
//                XCTFail("Should not produce error: \(error)")
//            }
//        }
//
//        waitForExpectations(timeout: 1)
//    }
//
//    /// Test if the service returns nil, we get an error back
//    ///
//    /// - Given: Predictions service with transcribe behavior
//    /// - When:
//    ///    - Invoke transcribe and if service return nil result
//    /// - Then:
//    ///    - I should get an error back
//    ///
//    func testNilResult() {
//        mockTranscribe.setResult(result: nil)
//
//        let errorReceived = expectation(description: "Error should be returned")
//
//        predictionsService.transcribe(speechToText: audioFile, language: nil) {event in
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
//}
