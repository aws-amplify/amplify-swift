//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import AWSTranscribeStreaming

extension AWSPredictionsService: AWSTranscribeStreamingServiceBehavior {

    func speechToText(audio: Data, onEvent: @escaping TranscribeServiceEventHandler) {

        let request: AWSTranscribeStreamingStartStreamTranscriptionRequest = AWSTranscribeStreamingStartStreamTranscriptionRequest()
        request.languageCode = .enUS
        request.mediaEncoding = .pcm
        request.mediaSampleRateHertz = 8_000

        let delegate = NativeWSTranscribeStreamingClientDelegate()

        delegate.connectionStatusCallback = { status, error in
            if status == .connected {
                DispatchQueue.main.async {
                   let headers = [
                       ":content-type": "audio/wav",
                       ":message-type": "event",
                       ":event-type": "AudioEvent"
                   ]

                    self.awsTranscribeStreaming.send(data: audio, headers: headers)
                    self.awsTranscribeStreaming.sendEndFrame()
                }
            }

            if status == .closed && error == nil {

            }
        }

        delegate.receiveEventCallback = { event, error in
            if let error = error {

                return
            }

            guard let event = event else {

                return
            }

            guard let transcriptEvent = event.transcriptEvent else {

                return
            }

            guard let results = transcriptEvent.transcript?.results else {
                print("No results, waiting for next event")
                return
            }

            guard let firstResult = results.first else {
                print("firstResult nil--possibly a partial result: \(event)")
                return
            }

            guard let isPartial = firstResult.isPartial as? Bool else {

                return
            }

            guard !isPartial else {
                print("Partial result received, waiting for next event (results: \(results))")
                return
            }

            print("Received final transcription event (results: \(results))")
            DispatchQueue.main.async {
                self.awsTranscribeStreaming.endTranscription()
            }
        }
        let callbackQueue = DispatchQueue(label: "TranscribeStreamingAmplify")
        awsTranscribeStreaming.setDelegate(delegate: delegate, callbackQueue: callbackQueue)
        awsTranscribeStreaming.startTranscriptionWSS(request: request)

    }
}
