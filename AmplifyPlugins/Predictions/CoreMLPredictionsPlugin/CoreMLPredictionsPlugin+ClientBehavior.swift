//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

#if canImport(Speech) && canImport(Vision)
import Foundation
import CoreGraphics
import Amplify
@_spi(PredictionsIdentifyRequestKind) import Amplify
@_spi(PredictionsConvertRequestKind) import Amplify

extension CoreMLPredictionsPlugin {
    public func identify<Output>(
        _ request: Predictions.Identify.Request<Output>,
        in image: URL,
        options: Predictions.Identify.Options?
    ) async throws -> Output {
        guard let coreMLVisionAdapter = coreMLVision else {
            throw PredictionsError.client(
                .init(
                    description: "CoreML Service is not configured",
                    recoverySuggestion: "Ensure that your configuration file is correct."
                )
            )
        }

        var predictionsError: PredictionsError {
            let errorDescription = CoreMLPluginErrorString.operationNotSupported.errorDescription
            let recovery = CoreMLPluginErrorString.operationNotSupported.recoverySuggestion
            let predictionsError = PredictionsError.service(
                .init(description: errorDescription, recoverySuggestion: recovery)
            )
            return predictionsError
        }

        switch request.kind {
        case .detectCelebrities,
                .detectEntities,
                .detectEntitiesCollection,
                .detectTextInDocument,
                .detectLabels(.moderation, _):
            throw predictionsError
        case let .detectText(lift):
            guard  let result = try coreMLVisionAdapter.detectText(image) else {
                let errorDescription = CoreMLPluginErrorString.detectTextNoResult.errorDescription
                let recovery = CoreMLPluginErrorString.detectTextNoResult.recoverySuggestion
                let predictionsError = PredictionsError.service(
                    .init(description: errorDescription, recoverySuggestion: recovery)
                )
                throw predictionsError
            }
            return lift.outputSpecificToGeneric(result)
        case let .detectLabels(_, lift):
            guard let result = try coreMLVisionAdapter.detectLabels(image) else {
                let errorDescription = CoreMLPluginErrorString.detectLabelsNoResult.errorDescription
                let recovery = CoreMLPluginErrorString.detectLabelsNoResult.recoverySuggestion
                let predictionsError = PredictionsError.service(
                    .init(description: errorDescription, recoverySuggestion: recovery)
                )
                throw predictionsError
            }
            return lift.outputSpecificToGeneric(result)
        }
    }

    public func convert<Input, Options, Output>(
        _ request: Predictions.Convert.Request<Input, Options, Output>,
        options: Options?
    ) async throws -> Output {
        var predictionsError: PredictionsError {
            let errorDescription = CoreMLPluginErrorString.operationNotSupported.errorDescription
            let recovery = CoreMLPluginErrorString.operationNotSupported.recoverySuggestion
            let predictionsError = PredictionsError.service(
                .init(description: errorDescription, recoverySuggestion: recovery)
            )
            return predictionsError
        }

        switch request.kind {
        case .textToSpeech, .textToTranslate:
            throw predictionsError
        case let .speechToText(lift):
            let options = lift.optionsGenericToSpecific(options) ?? .init()
            let input = lift.inputGenericToSpecific(request.input)
            let request = Predictions.Convert.SpeechToText.Request(
                speechToText: input,
                options: options
            )
            let stream = AsyncThrowingStream<Predictions.Convert.SpeechToText.Result, Error> { continuation in
                Task {
                    do {
                        let result = try await coreMLSpeech.getTranscription(
                            request.speechToText
                        )
                        continuation.yield(
                            .init(transcription: result.bestTranscription.formattedString)
                        )
                        if result.isFinal {
                            continuation.finish()
                        }
                    } catch {
                        continuation.yield(with: .failure(error))
                    }
                }
            }

            return lift.outputSpecificToGeneric(stream)
        }
    }

    public func interpret(
        text: String,
        options: Predictions.Interpret.Options?
    ) async throws -> Predictions.Interpret.Result {
        guard let naturalLanguageAdapter = coreMLNaturalLanguage else {
            throw PredictionsError.client(
                .init(
                    description: "CoreML Service is not configured",
                    recoverySuggestion: "Ensure that your configuration file is correct."
                )
            )
        }

        let language = naturalLanguageAdapter.detectDominantLanguage(for: text)
            .map { Predictions.Language.DetectionResult(languageCode: $0, score: nil) }

        let syntax = naturalLanguageAdapter.getSyntaxTokens(for: text)
        let entities = naturalLanguageAdapter.getEntities(for: text)
        let sentiment = naturalLanguageAdapter.getSentiment(for: text)

        let predictionsSentiment: Predictions.Sentiment
        switch sentiment {
        case 0.0:
            predictionsSentiment = Predictions.Sentiment(predominantSentiment: .neutral, sentimentScores: nil)
        case -1.0 ..< 0.0:
            predictionsSentiment = Predictions.Sentiment(predominantSentiment: .negative, sentimentScores: nil)
        case 0.0 ... 1.0:
            predictionsSentiment = Predictions.Sentiment(predominantSentiment: .positive, sentimentScores: nil)
        default:
            predictionsSentiment = Predictions.Sentiment(predominantSentiment: .mixed, sentimentScores: nil)
        }

        let result = Predictions.Interpret.Result(
            keyPhrases: nil,
            sentiment: predictionsSentiment,
            entities: entities,
            language: language,
            syntax: syntax
        )

        return result
    }
}
#endif
