//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
import Speech
import Amplify
@testable import CoreMLPredictionsPlugin

class CoreMLSpeechAdapterTests: XCTestCase {
    var coreMLSpeechAdapter: MockCoreMLSpeechAdapter!

    override func setUp() {
        coreMLSpeechAdapter = MockCoreMLSpeechAdapter()
    }

    func testTranscriptionResponseNil() async throws {
        let testBundle = Bundle(for: type(of: self))
        guard let url = testBundle.url(forResource: "audio", withExtension: "wav") else {
            return
        }
        coreMLSpeechAdapter.setResponse(result: nil)
        let result = try await coreMLSpeechAdapter.getTranscription(url)
        XCTAssertNil(result)
    }

    func testTranscriptionResponse() async throws {
        let testBundle = Bundle(for: type(of: self))
        guard let url = testBundle.url(forResource: "audio", withExtension: "wav") else {
            return
        }
        let mockResult = Predictions.Convert.SpeechToText.Result(transcription: "This is a test")
        coreMLSpeechAdapter.setResponse(result: mockResult)
        let result = try await coreMLSpeechAdapter.getTranscription(url)
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.transcription, mockResult.transcription)
    }
}
