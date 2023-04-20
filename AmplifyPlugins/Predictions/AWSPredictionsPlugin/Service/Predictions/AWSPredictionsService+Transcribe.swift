//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify
import AWSPluginsCore
import AWSTranscribeStreaming

extension AWSPredictionsService: AWSTranscribeStreamingServiceBehavior {
    func transcribe(
        speechToText: URL,
        language: LanguageType?,
        region: String
    ) async throws -> AsyncThrowingStream<Predictions.Convert.SpeechToText.Result, Error> {
        let audioData = try Data(contentsOf: speechToText)
        // if a language is passed in, we'll use that
        let language = language?.toTranscribeLanguage()
        // if not, we'll try to grab one from the config
        ?? predictionsConfig.convert.transcription?.language.toTranscribeLanguage()
        // if there's no default language present in the config, we'll default to `enUs`
        ?? .enUs

        // Info needed by the service adaptor to generate a proper request.
        let input = AWSTranscribeStreamingAdapter.StartStreamInput(
            audioStream: audioData,
            languageCode: language,
            mediaEncoding: .pcm,
            mediaSampleRateHertz: 8000
        )

        // map each `TranscribeStreamingClientTypes.TranscriptEvent` received from the service
        // adaptor to a `SpeechToTextResult` and yield them to the stream.
        let stream = AsyncThrowingStream<Predictions.Convert.SpeechToText.Result, Error> { continuation in
            Task {
                do {
                    for try await transcription in try await awsTranscribeStreaming.startStreamTranscription(
                        input: input,
                        region: region
                    ) {
                        continuation.yield(
                            Predictions.Convert.SpeechToText.Result(
                                transcription: transcription.transcript?.results?.first?.alternatives?.first?.transcript ?? ""
                            )
                        )
                        let isPartial = transcription.transcript?.results?.map(\.isPartial) ?? []
                        let shouldContinue = isPartial.allSatisfy { $0 }
                        if !shouldContinue { continuation.finish() }
                    }
                } catch let error as URLError {
                    continuation.finish(
                        throwing: PredictionsError.network(
                            "URLError encountered while trying to establish connection",
                            "Ensure your configuration is properly set up.",
                            error
                        )
                    )
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }

        return stream
    }
}
