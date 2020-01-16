//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
import AWSTranscribeStreaming
import Amplify
@testable import AWSPredictionsPlugin

class PredictionsServiceTranscribeTests: XCTestCase {

    var predictionsService: AWSPredictionsService!
    let mockTranscribe = MockTranscribeBehavior()
    var audioFile: URL!

    override func setUp() {
        let mockConfigurationJSON = """
        {
            "defaultRegion": "us_east_1"
        }
        """.data(using: .utf8)!

        do {
            let mockConfiguration = try JSONDecoder().decode(PredictionsPluginConfiguration.self,
                                                             from: mockConfigurationJSON)

            predictionsService = AWSPredictionsService(identifier: "",
                                                       awsTranslate: MockTranslateBehavior(),
                                                       awsRekognition: MockRekognitionBehavior(),
                                                       awsTextract: MockTextractBehavior(),
                                                       awsComprehend: MockComprehendBehavior(),
                                                       awsPolly: MockPollyBehavior(),
                                                       awsTranscribeStreaming: MockTranscribeBehavior(),
                                                       transcribeDelegate: NativeWSTranscribeStreamingClientDelegate(),
                                                       transcribeCallbackQueue: DispatchQueue(label: "TranscribeStreamingTestQueue"),
                                                       configuration: mockConfiguration)

            let testBundle = Bundle(for: type(of: self))
            guard let url = testBundle.url(forResource: "audio", withExtension: "wav") else {
                return
            }
            audioFile = url
        } catch {
            XCTFail("Initialization of the test failed")
        }
    }

    func createMockTranscribeResponse() -> AWSTranscribeStreamingTranscriptResultStream {
        let mockResponse = AWSTranscribeStreamingTranscriptResultStream()!
        let transcriptEvent = AWSTranscribeStreamingTranscriptEvent()!
        let str = "This is a test"
        let results = AWSTranscribeStreamingTranscript()!
        let resultStream = AWSTranscribeStreamingResult()!
        let alternative = AWSTranscribeStreamingAlternative()!
        alternative.transcript = str
        resultStream.alternatives = [alternative]
        results.results = [resultStream]
        transcriptEvent.transcript = results
        return mockResponse
    }

    /// Test whether we can make a successful transcribe call
    ///
    /// - Given: Predictions service with transcribe behavior
    /// - When:
    ///    - I invoke transcribe api in predictions service
    /// - Then:
    ///    - I should get back a result
    ///
    func testTranscribeService() {
         let transcription = "This is a test"
        predictionsService.transcribe(speechToText: audioFile) { event in
            switch event {
            case .completed(let result):
                let speechToTextResult = result as? SpeechToTextResult
                XCTAssertEqual(speechToTextResult?.transcription, transcription, "transcribed text should be the same")
            case .failed(let error):
                XCTFail("Should not produce error: \(error)")
            }

        }

    }
}
