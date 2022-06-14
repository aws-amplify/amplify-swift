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

    override func setUp() async throws {
        coreMLSpeechAdapter = MockCoreMLSpeechAdapter()
    }

    func testTranscriptionResponseNil() {
        let testBundle = Bundle(for: type(of: self))
        guard let url = testBundle.url(forResource: "audio", withExtension: "wav") else {
            return
        }
        coreMLSpeechAdapter.setResponse(result: nil)
        let callbackExpectation = expectation(description: "callback reached")
        coreMLSpeechAdapter.getTranscription(url) { result in
            XCTAssertNil(result)
            callbackExpectation.fulfill()
        }

        waitForExpectations(timeout: 180)
    }

    func testTranscriptionResponse() {
        let testBundle = Bundle(for: type(of: self))
        guard let url = testBundle.url(forResource: "audio", withExtension: "wav") else {
            return
        }
        let mockResult = SpeechToTextResult(transcription: "This is a test")
        coreMLSpeechAdapter.setResponse(result: mockResult)
         let callbackExpectation = expectation(description: "callback reached")
        coreMLSpeechAdapter.getTranscription(url) { result in
            XCTAssertNotNil(result)
            XCTAssertEqual(result?.transcription, mockResult.transcription)
            callbackExpectation.fulfill()
        }

        waitForExpectations(timeout: 180)
    }
}
