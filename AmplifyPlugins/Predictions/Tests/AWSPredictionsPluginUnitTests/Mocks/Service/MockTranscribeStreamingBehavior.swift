//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import AWSTranscribeStreaming
import XCTest
@testable import AWSPredictionsPlugin

class MockTranscribeBehavior: AWSTranscribeStreamingBehavior {
    var startStreamingResult: ((AWSTranscribeStreamingAdapter.StartStreamInput) async throws -> AsyncThrowingStream<TranscribeStreamingClientTypes.TranscriptEvent, Error>)?

    func startStreamTranscription(input: AWSTranscribeStreamingAdapter.StartStreamInput) async throws -> AsyncThrowingStream<TranscribeStreamingClientTypes.TranscriptEvent, Error> {
        guard let startStreamingResult else { throw MockBehaviorDefaultError() }
        return try await startStreamingResult(input)
    }
}
