//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
import Amplify
@testable import CoreMLPredictionsPlugin

class MockCoreMLSpeechAdapter: CoreMLSpeechBehavior {
    var response: SpeechToTextResult?

    func getTranscription(_ audioData: URL) async throws -> SpeechToTextResult? {
        response
    }


//    func getTranscription(_ audioData: URL, callback: @escaping (SpeechToTextResult?) -> Void) {
//        callback(response)
//    }

    func setResponse(result: SpeechToTextResult?) {
        response = result
    }
}
