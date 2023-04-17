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
    var response: Predictions.Convert.SpeechToText.Result?

    func getTranscription(_ audioData: URL) async throws -> Predictions.Convert.SpeechToText.Result? {
        response
    }

    func setResponse(result: Predictions.Convert.SpeechToText.Result?) {
        response = result
    }
}
