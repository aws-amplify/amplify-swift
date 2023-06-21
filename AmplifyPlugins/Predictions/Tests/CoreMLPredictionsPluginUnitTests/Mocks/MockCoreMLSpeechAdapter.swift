//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
import Amplify
import Speech
@testable import CoreMLPredictionsPlugin

class MockCoreMLSpeechAdapter: CoreMLSpeechBehavior {
    var response: SFSpeechRecognitionResult

    init(response: SFSpeechRecognitionResult) {
        self.response = response
    }

    func getTranscription(_ audioData: URL) async throws -> SFSpeechRecognitionResult {
        response
    }
}
