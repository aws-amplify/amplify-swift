//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import AWSCore
import AWSTranscribeStreaming
@testable import AWSPredictionsPlugin

class MockTranscribeBehavior: AWSTranscribeStreamingBehavior {

    var transcriptionResult: AWSTranscribeStreamingTranscriptResultStream?
    var error: Error?

    func getTranscribeStreaming() -> AWSTranscribeStreaming {
        return AWSTranscribeStreaming()
    }

    public func setError(error: Error) {
        transcriptionResult = nil
        self.error = error
    }

    public func setResult(result: AWSTranscribeStreamingTranscriptResultStream?) {
        transcriptionResult = result
    }

    func startTranscriptionWSS(request: AWSTranscribeStreamingStartStreamTranscriptionRequest) {

    }

    func setDelegate(delegate: AWSTranscribeStreamingClientDelegate, callbackQueue: DispatchQueue) {

    }

    func send(data: Data, headers: [String: String]) {

    }

    func sendEndFrame() {

    }

    func endTranscription() {

    }
}
