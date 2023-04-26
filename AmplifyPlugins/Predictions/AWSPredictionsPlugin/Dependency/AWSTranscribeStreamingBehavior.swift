//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify
import AWSTranscribeStreaming

protocol AWSTranscribeStreamingBehavior {
    func startStreamTranscription(
        input: AWSTranscribeStreamingAdapter.StartStreamInput,
        region: String
    ) async throws -> AsyncThrowingStream<TranscribeStreamingClientTypes.TranscriptEvent, Error>
}
