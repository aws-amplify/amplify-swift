//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

// TODO: Add hand rolled implementation

import Foundation
import AWSTranscribeStreaming

//protocol AWSTranscribeStreamingBehavior {
//
//    func getTranscribeStreaming() -> TranscribeStreamingClient
//
//    /// delegate and callback queue must be set before calling start transcription.
//    /// instantiate a class that conforms to the delegate protcol below and pass it in
////    func setDelegate(delegate: AWSTranscribeStreamingClientDelegate, callbackQueue: DispatchQueue)
//
//    /// this call will instantiate the web socket provider class that was passed in at the time of
//    /// registering the AWS Transcribe Streaming SDK class and it will call open on the socket
//    func startStreamTranscription(
//        request: StartStreamTranscriptionInput
//    ) async throws -> StartStreamTranscriptionOutputResponse
//
//    /// this call should be called after the socket is open to send data over the socket with
//    /// the appropriate headers that aws transcribe requires i.e. contentType, eventType, etc
////    func send(data: Data, headers: [String: String])
////
////    func sendEndFrame()
////
////    func endTranscription()
//}
