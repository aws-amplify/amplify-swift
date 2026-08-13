//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

// See CoreMLSpeechBehavior for why tvOS is excluded here.
#if canImport(Speech) && !os(tvOS)
import Amplify
import Speech
import XCTest
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
#endif
