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

class PredictionsServiceTranscribeTests: XCTestCase {
    var predictionsService: AWSPredictionsService!
    let mockTranscribe = MockTranscribeBehavior()
    var audioFile: URL!

    let mockError = NSError(
        domain: "aws.transcribe.errordomain",
        code: 42,
        userInfo: [:]
    )

    override func setUp() {
        let mockConfigurationJSON = """
        {
            "defaultRegion": "us_east_1"
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
                awsTextract: MockTextractBehavior(),
                awsComprehend: MockComprehendBehavior(),
                awsPolly: MockPollyBehavior(),
                awsTranscribeStreaming: mockTranscribe,
                configuration: mockConfiguration
            )

            audioFile = try XCTUnwrap(
                Bundle.module.url(forResource: "audio", withExtension: "wav", subdirectory: "TestImages")
            )
        } catch {
            XCTFail("Initialization of the test failed")
        }
    }

    func createMockTranscribeResponse() -> AsyncThrowingStream<TranscribeStreamingClientTypes.TranscriptEvent, Error> {
        return .init { continuation in
            continuation.yield(
                TranscribeStreamingClientTypes.TranscriptEvent(
                    transcript: .init(
                        results: [
                            .init(
                                alternatives: [.init(transcript: "This is a test")],
                                endTime: 1,
                                isPartial: false,
                                startTime: 0
                            )
                        ]
                    )
                )
            )

            continuation.finish()
        }
    }

    /// Test whether we can make a successful transcribe call
    ///
    /// - Given: Predictions service with transcribe behavior
    /// - When:
    ///    - I invoke transcribe api in predictions service
    /// - Then:
    ///    - I should get back a result
    func testTranscribeService() async throws {
        let mockResponse = createMockTranscribeResponse()
        mockTranscribe.startStreamingResult = { _, _ in
            mockResponse
        }
        let expectedTranscription = "This is a test"

        let result = try await predictionsService.transcribe(
            speechToText: audioFile,
            language: .usEnglish,
            region: "us-east-1"
        )

        for try await transcript in result.map(\.transcription) {
            print(transcript)
            XCTAssertEqual(transcript, expectedTranscription, "transcribed text should be the same")
            break
        }
    }

    /// Test whether error is correctly propogated
    ///
    /// - Given: Predictions service with transcribe behavior
    /// - When:
    ///    - I invoke an invalid request
    /// - Then:
    ///    - I should get back a service error
    func testTranscribeServiceWithError() async throws {
        mockTranscribe.startStreamingResult = { _, _ in throw self.mockError }

        do {
            let result = try await predictionsService.transcribe(speechToText: audioFile, language: .usEnglish, region: "us-east-1")
            for try await value in result {
                XCTFail("Should not produce value: \(value)")
            }
        } catch {
            XCTAssertNotNil(error, "Should produce an error")
        }

    }

    /// Test whether error is correctly propogated
    ///
    /// - Given: Predictions service with transcribe behavior
    /// - When:
    ///    - I invoke an invalid request with Unreachable host
    /// - Then:
    ///    - I should get back a connection error
    ///
    func testTranscribeServiceWithCannotFindHostError() async throws {
        let urlError = URLError(.cannotFindHost)
        mockTranscribe.startStreamingResult = { _, _ in throw urlError }

        do {
            let result = try await predictionsService.transcribe(speechToText: audioFile, language: .usEnglish, region: "us-east-1")
            for try await value in result {
                XCTFail("Should not produce value: \(value)")
            }
        } catch let error as PredictionsError {
            guard case .network = error else {
                XCTFail("Should produce an network error instead of \(error)")
                return
            }
        }
    }

    /// Test if language from configuration is picked up
    ///
    /// - Given: Predictions service with transcribe behavior. And language is set in config
    /// - When:
    ///    - Invoke transcribe
    /// - Then:
    ///    - I should get a successful result
    ///
    func testLanguageFromConfiguration() async throws {
        let mockConfigurationJSON = """
                {
                    "defaultRegion": "us-east-1",
                    "convert": {
                        "transcription": {
                            "region": "us-east-1",
                            "language": "en-US"
                        }
                    }
                }
                """

        let mockConfiguration = try JSONDecoder().decode(
            PredictionsPluginConfiguration.self,
            from: Data(mockConfigurationJSON.utf8)
        )
        predictionsService = AWSPredictionsService(
            identifier: "",
            awsTranslate: MockTranslateBehavior(),
            awsRekognition: MockRekognitionBehavior(),
            awsTextract: MockTextractBehavior(),
            awsComprehend: MockComprehendBehavior(),
            awsPolly: MockPollyBehavior(),
            awsTranscribeStreaming: mockTranscribe,
            configuration: mockConfiguration
        )


        let mockResponse = createMockTranscribeResponse()
        mockTranscribe.startStreamingResult = { _, _ in mockResponse }

        let expectedTranscription = "This is a test"


        let result = try await predictionsService.transcribe(speechToText: audioFile, language: nil, region: "us-east-1")
        for try await value in result {
            XCTAssertEqual(value.transcription, expectedTranscription, "Transcribed text should be the same")
            break
        }
    }
}

