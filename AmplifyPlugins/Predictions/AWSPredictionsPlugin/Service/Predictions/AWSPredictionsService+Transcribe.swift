//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import AWSTranscribeStreaming

extension AWSPredictionsService: AWSTranscribeStreamingServiceBehavior {

    func transcribe(speechToText: URL, onEvent: @escaping TranscribeServiceEventHandler) {

        guard let audioData = try? Data(contentsOf: speechToText) else {

            onEvent(.failed(.network(AWSTranscribeStreamingErrorMessage.badRequest.errorDescription,
                                     AWSTranscribeStreamingErrorMessage.badRequest.recoverySuggestion)))
                   return
        }

        let request: AWSTranscribeStreamingStartStreamTranscriptionRequest =
            AWSTranscribeStreamingStartStreamTranscriptionRequest()
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

                    self.awsTranscribeStreaming.send(data: audioData, headers: headers)
                    self.awsTranscribeStreaming.sendEndFrame()
                }
            }

            if status == .closed && error != nil {
                let conflict = AWSTranscribeStreamingErrorMessage.conflict
                onEvent(.failed(.network(conflict.errorDescription, conflict.recoverySuggestion)))
            }
        }

        delegate.receiveEventCallback = { event, error in
           guard error == nil else {
            let error = error as NSError?
            let predictionsErrorString = PredictionsErrorHelper.mapPredictionsServiceError(error!)
            onEvent(.failed(.network(
                predictionsErrorString.errorDescription,
                predictionsErrorString.recoverySuggestion)))
            return
            }

            guard let event = event, let transcriptEvent = event.transcriptEvent else {
                onEvent(.failed(.unknown("No result was found. An unknown error occurred.", "Please try again.")))
                return
            }

            guard let transcribedResults = transcriptEvent.transcript?.results else {
                let badRequest = AWSTranscribeStreamingErrorMessage.badRequest
                onEvent(.failed(.network(badRequest.errorDescription, badRequest.recoverySuggestion)))
                return
            }

            guard let firstResult = transcribedResults.first else {
                print("firstResult nil--possibly a partial result: \(event)")
                return
            }

            guard let isPartial = firstResult.isPartial as? Bool else {
                return
            }

            guard !isPartial else {
                print("Partial result received, waiting for next event (results: \(transcribedResults))")
                return
            }

            print("Received final transcription event (results: \(transcribedResults))")
            let transcribeResult = ConvertSpeechToTextTransformers.processTranscription(transcribedResults)
            onEvent(.completed(transcribeResult))
            self.awsTranscribeStreaming.endTranscription()

        }
        let callbackQueue = DispatchQueue(label: "TranscribeStreamingAmplify")
        awsTranscribeStreaming.setDelegate(delegate: delegate, callbackQueue: callbackQueue)
        awsTranscribeStreaming.startTranscriptionWSS(request: request)

    }
}
