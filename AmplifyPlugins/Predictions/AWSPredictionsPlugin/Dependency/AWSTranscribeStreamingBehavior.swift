//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import AWSTranscribeStreaming

protocol AWSTranscribeStreamingBehavior {

    func getTranscribeStreaming() -> AWSTranscribeStreaming

    func setDelegate(delegate: AWSTranscribeStreamingClientDelegate, callbackQueue: DispatchQueue)

    func startTranscriptionWSS(request: AWSTranscribeStreamingStartStreamTranscriptionRequest)

    func send(data: Data, headers: [String: String])

    func sendEndFrame()

    func endTranscription()
}
