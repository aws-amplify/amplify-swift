//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import AWSTranscribeStreaming

extension AWSPredictionsService: AWSTranscribeStreamingServiceBehavior {

    // swiftlint:disable cyclomatic_complexity
    func transcribe(speechToText: URL, language: LanguageType?, onEvent: @escaping TranscribeServiceEventHandler) {

        guard let audioData = try? Data(contentsOf: speechToText) else {

            onEvent(.failed(.network(AWSTranscribeStreamingErrorMessage.badRequest.errorDescription,
                                     AWSTranscribeStreamingErrorMessage.badRequest.recoverySuggestion)))
            return
        }

        let request: AWSTranscribeStreamingStartStreamTranscriptionRequest =
            AWSTranscribeStreamingStartStreamTranscriptionRequest()
        if let languageCode = language?.toTranscribeLanguage() {
            request.languageCode = languageCode
        } else {
            request.languageCode = predictionsConfig.convert.transcription?.language.toTranscribeLanguage() ?? .enUS
        }
        request.mediaEncoding = .pcm
        request.mediaSampleRateHertz = 8_000

        transcribeClientDelegate.connectionStatusCallback = { status, error in
            if status == .closed && error != nil {
                guard error != nil else {
                    return
                }
                let nsError = error as NSError?
                let predictionsError = PredictionsErrorHelper.mapPredictionsServiceError(nsError!)
                if case .network = predictionsError {
                    onEvent(.failed(predictionsError))
                    return
                }
            } else if status == .connected {
                let headers = [
                    ":content-type": "audio/wav",
                    ":message-type": "event",
                    ":event-type": "AudioEvent"
                ]
                let chunkSize = 4_096
                let audioDataSize = audioData.count
                var currentStart = 0
                var currentEnd = min(chunkSize, audioDataSize - currentStart)

                while currentStart < audioDataSize {
                    let dataChunk = audioData[currentStart ..< currentEnd]
                    self.awsTranscribeStreaming.send(data: dataChunk, headers: headers)

                    currentStart = currentEnd
                    currentEnd = min(currentStart + chunkSize, audioDataSize)
                }
                self.awsTranscribeStreaming.sendEndFrame()
            }
        }

        transcribeClientDelegate.receiveEventCallback = { event, error in
            guard error == nil else {
                let error = error as NSError?
                let predictionsErrorString = PredictionsErrorHelper.mapPredictionsServiceError(error!)
                onEvent(.failed(.network(
                    predictionsErrorString.errorDescription,
                    predictionsErrorString.recoverySuggestion)))
                return
            }

            guard let event = event else {
                onEvent(.failed(.unknown("No result was found. An unknown error occurred.", "Please try again.")))
                return
            }

            guard let transcriptEvent = event.transcriptEvent else {
                onEvent(.failed(.unknown("No transcript event, an unknown error occurred.", "Please try again")))
                return
            }

            guard let transcribedResults = transcriptEvent.transcript?.results else {
                let badRequest = AWSTranscribeStreamingErrorMessage.badRequest
                onEvent(.failed(.network(badRequest.errorDescription, badRequest.recoverySuggestion)))
                return
            }

            guard let firstResult = transcribedResults.first,
                let isPartial = firstResult.isPartial as? Bool else {
                    return
            }

            guard !isPartial else {
                self.log.verbose("Partial result received, waiting for next event (results: \(transcribedResults))")
                return
            }

            self.log.verbose("Received final transcription event (results: \(transcribedResults))")

            if let transcribeResult = ConvertSpeechToTextTransformers.processTranscription(transcribedResults) {
                self.awsTranscribeStreaming.endTranscription()
                onEvent(.completed(transcribeResult))
                return
            }
        }

        awsTranscribeStreaming.startTranscriptionWSS(request: request)

    }
}
