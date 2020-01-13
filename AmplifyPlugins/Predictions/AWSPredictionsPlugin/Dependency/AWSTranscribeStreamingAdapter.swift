//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
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

}
