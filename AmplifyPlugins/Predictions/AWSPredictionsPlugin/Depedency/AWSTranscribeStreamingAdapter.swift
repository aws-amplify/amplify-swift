//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify
// TODO: Add hand rolled implementation

import AWSTranscribeStreaming

struct _StartStreamTranscriptionInput {
    let languageType: LanguageType
}


class _TranscribeStreamingSession {
    // let webSocket: WebSocket

    func send(_ event: _Event) {
        // webSocket.send(event)
    }
}

extension _TranscribeStreamingSession {
    struct _Event {
        let data: Data
        static func audio(_ data: Data) -> _Event {
            .init(data: data)
        }
    }
}

class _AWSTranscribeStreamingAdapter {
    func startStreamTranscription(
        request:  _StartStreamTranscriptionInput,
        onEvent: @escaping (_TranscribeStreamingSession._Event) -> Void
    ) async throws -> _TranscribeStreamingSession {
        fatalError()
    }

    func startStreamTranscription(
        url: URL,
        languageType: LanguageType,
        onEvent: @escaping (_TranscribeStreamingSession._Event) -> Void
    ) {
        
    }
}

protocol _AWSTranscribeStreamingBehavior {
    func startStreamTranscription(
        request:  _StartStreamTranscriptionInput,
        onEvent: @escaping (_TranscribeStreamingSession._Event) -> Void
    ) async throws -> _TranscribeStreamingSession

    func startStreamTranscription(
        url: URL,
        languageType: LanguageType,
        onEvent: @escaping (_TranscribeStreamingSession._Event) -> Void
    )
}

//class AWSTranscribeStreamingAdapter: AWSTranscribeStreamingBehavior {
//
//    let transcribeStreamingClient:  TranscribeStreamingClient
//
//    init(_ transcribeStreamingClient: TranscribeStreamingClient) {
//        self.transcribeStreamingClient = transcribeStreamingClient
//    }
//
//    func getTranscribeStreaming() -> TranscribeStreamingClient {
//        return transcribeStreamingClient
//    }
//
////    func setDelegate(delegate: AWSTranscribeStreamingClientDelegate, callbackQueue: DispatchQueue) {
////        return transcribeStreamingClient.setDelegate(delegate, callbackQueue: callbackQueue)
////    }
//
//    func startStreamTranscription(
//        request: AWSTranscribeStreaming.StartStreamTranscriptionInput
//    ) async throws -> AWSTranscribeStreaming.StartStreamTranscriptionOutputResponse {
//        try await transcribeStreamingClient.startStreamTranscription(input: request)
//    }
//
////
////    func send(data: Data, headers: [String: String]) {
////        return transcribeStreamingClient.send(data, headers: headers)
////    }
////
////    func sendEndFrame() {
////        return transcribeStreamingClient.sendEndFrame()
////    }
////
////    func endTranscription() {
////        return transcribeStreamingClient.endTranscription()
////    }
//}
