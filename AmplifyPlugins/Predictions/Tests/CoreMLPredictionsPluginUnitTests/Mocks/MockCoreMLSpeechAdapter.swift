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

/// Returns `CoreMLSpeechTranscription` to match `CoreMLSpeechBehavior`, which no longer hands back a
/// non-`Sendable` `SFSpeechRecognitionResult`.
final class MockCoreMLSpeechAdapter: CoreMLSpeechBehavior {
    let response: CoreMLSpeechTranscription

    init(response: CoreMLSpeechTranscription) {
        self.response = response
    }

    func getTranscription(_ audioData: URL) async throws -> CoreMLSpeechTranscription {
        response
    }
}
#endif
