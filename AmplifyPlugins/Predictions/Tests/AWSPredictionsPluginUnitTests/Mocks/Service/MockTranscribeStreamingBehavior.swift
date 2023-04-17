//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
import Amplify
import AWSTranscribeStreaming
@testable import AWSPredictionsPlugin

class MockTranscribeBehavior: AWSTranscribeStreamingBehavior {
    var startStreamingResult: ((AWSTranscribeStreamingAdapter.StartStreamInput, String) async throws -> AsyncThrowingStream<TranscribeStreamingClientTypes.TranscriptEvent, Error>)? = nil

    func startStreamTranscription(input: AWSTranscribeStreamingAdapter.StartStreamInput, region: String) async throws -> AsyncThrowingStream<TranscribeStreamingClientTypes.TranscriptEvent, Error> {
        guard let startStreamingResult = startStreamingResult else { throw MockBehaviorDefaultError() }
        return try await startStreamingResult(input, region)
    }
}
