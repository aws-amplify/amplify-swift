//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import AWSTranscribeStreaming

class AWSTranscribeStreamingAdapter: AWSTranscribeStreamingBehavior {

    let awsTranscribeStreaming: AWSTranscribeStreaming

    init(_ awsTranscribeStreaming: AWSTranscribeStreaming) {
        self.awsTranscribeStreaming = awsTranscribeStreaming
    }

    func getTranscribeStreaming() -> AWSTranscribeStreaming {
        return awsTranscribeStreaming
    }

    func setDelegate(delegate: AWSTranscribeStreamingClientDelegate, callbackQueue: DispatchQueue) {
        return awsTranscribeStreaming.setDelegate(delegate, callbackQueue: callbackQueue)
    }

    func startTranscriptionWSS(request: AWSTranscribeStreamingStartStreamTranscriptionRequest) {
        return awsTranscribeStreaming.startTranscriptionWSS(request)
    }

    func send(data: Data, headers: [String: String]) {
        return awsTranscribeStreaming.send(data, headers: headers)
    }

    func sendEndFrame() {
        return awsTranscribeStreaming.sendEndFrame()
    }

    func endTranscription() {
        return awsTranscribeStreaming.endTranscription()
    }

}
