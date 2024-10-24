//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import AWSTranscribeStreaming
import Foundation

protocol AWSTranscribeStreamingBehavior {
    func startStreamTranscription(
        input: AWSTranscribeStreamingAdapter.StartStreamInput
    ) async throws -> AsyncThrowingStream<TranscribeStreamingClientTypes.TranscriptEvent, Error>
}
