//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

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
            throw SomeError()
        }

//        let options = options ?? .init()
        var predictionsError: PredictionsError {
            let errorDescription = CoreMLPluginErrorString.operationNotSupported.errorDescription
            let recovery = CoreMLPluginErrorString.operationNotSupported.recoverySuggestion
            let predictionsError = PredictionsError.service(errorDescription, recovery, nil)
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
            guard  let result = coreMLVisionAdapter.detectText(image) else {
                let errorDescription = CoreMLPluginErrorString.detectTextNoResult.errorDescription
                let recovery = CoreMLPluginErrorString.detectTextNoResult.recoverySuggestion
                let predictionsError = PredictionsError.service(errorDescription, recovery, nil)
                throw predictionsError
            }
            return lift.outputSpecificToGeneric(result)
        case let .detectLabels(_, lift):
            guard let result = coreMLVisionAdapter.detectLabels(image) else {
                let errorDescription = CoreMLPluginErrorString.detectLabelsNoResult.errorDescription
                let recovery = CoreMLPluginErrorString.detectLabelsNoResult.recoverySuggestion
                let predictionsError = PredictionsError.service(errorDescription, recovery, nil)
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
            let predictionsError = PredictionsError.service(errorDescription, recovery, nil)
            return predictionsError
        }

        switch request.kind {
        case .textToSpeech, .textToTranslate:
            throw predictionsError
        case let .speechToText(lift):
            let options = lift.optionsGenericToSpecific(options) ?? .init()
            let input = lift.inputGenericToSpecific(request.input)
            let request = PredictionsSpeechToTextRequest(
                speechToText: input,
                options: options
            )
            let stream = AsyncThrowingStream<SpeechToTextResult, Error> { continuation in
                Task {
                    let result = try await coreMLSpeech.getTranscription(
                        request.speechToText
                    )

                    guard let result = result else {
                        let errorDescription = CoreMLPluginErrorString.transcriptionNoResult.errorDescription
                        let recovery = CoreMLPluginErrorString.transcriptionNoResult.recoverySuggestion
                        let predictionsError = PredictionsError.service(errorDescription, recovery, nil)
                        continuation.finish(throwing: predictionsError)
                        return
                    }
                    continuation.yield(result)
                }
            }

            return lift.outputSpecificToGeneric(stream)
        }
    }

    public func interpret(
        text: String,
        options: Predictions.Interpret.Options?
    ) async throws -> Predictions.Interpret.Result {
//        let options = options ?? Predictions.Interpret.Options()
//        let request = Predictions.Interpret.Request(
//            textToInterpret: text,
//            options: options
//        )

        guard let naturalLanguageAdapter = coreMLNaturalLanguage else {
            throw SomeError()
        }

        var interpretResultBuilder = Predictions.Interpret.Result.Builder()
        if let dominantLanguage = naturalLanguageAdapter.detectDominantLanguage(
            for: text // request.textToInterpret
        ) {
            let languageResult = LanguageDetectionResult(
                languageCode: dominantLanguage,
                score: nil
            )
            interpretResultBuilder.with(
                language: languageResult
            )
        }

        let syntaxToken = naturalLanguageAdapter.getSyntaxTokens(
            for: text // request.textToInterpret
        )

        interpretResultBuilder.with(syntax: syntaxToken)

        let entities = naturalLanguageAdapter
            .getEntities(
                for: text// request.textToInterpret
            )

        interpretResultBuilder.with(entities: entities)

        let sentiment = naturalLanguageAdapter.getSentiment(for: text) //request.textToInterpret)
        let amplifySentiment: Sentiment
        switch sentiment {
        case 0.0:
            amplifySentiment = Sentiment(predominantSentiment: .neutral, sentimentScores: nil)
        case -1.0 ..< 0.0:
            amplifySentiment = Sentiment(predominantSentiment: .negative, sentimentScores: nil)
        case 0.0 ... 1.0:
            amplifySentiment = Sentiment(predominantSentiment: .positive, sentimentScores: nil)
        default:
            amplifySentiment = Sentiment(predominantSentiment: .mixed, sentimentScores: nil)
        }
        interpretResultBuilder.with(sentiment: amplifySentiment)

        let interpretResult = interpretResultBuilder.build()
        return interpretResult
//        dispatch(result: .success(interpretResult))
    }

}

// TODO: Remove
struct SomeError: Error {}



//    public func convert(
//        textToTranslate: String,
//        language: LanguageType?,
//        targetLanguage: LanguageType?,
//        options: PredictionsTranslateTextRequest.Options?
//    ) async throws -> TranslateTextResult {
//
//        let options = options ?? PredictionsTranslateTextRequest.Options()
//        let request = PredictionsTranslateTextRequest(
//            textToTranslate: textToTranslate,
//            targetLanguage: targetLanguage,
//            language: language,
//            options: options
//        )
//        _ = options
//        _ = request
//
//        let errorDescription = CoreMLPluginErrorString.operationNotSupported.errorDescription
//        let recovery = CoreMLPluginErrorString.operationNotSupported.recoverySuggestion
//        let predictionsError = PredictionsError.service(errorDescription, recovery, nil)
//        throw predictionsError
//
//        // TODO: Dispatch to Hub???
//        // dispatch(result: .failure(predictionsError))
//    }
//
//    public func convert(
//        textToSpeech: String,
//        options: PredictionsTextToSpeechRequest.Options? = nil
//    ) async throws -> TextToSpeechResult {
//        let options = options ?? PredictionsTextToSpeechRequest.Options()
//        let request = PredictionsTextToSpeechRequest(
//            textToSpeech: textToSpeech,
//            options: options
//        )
//        _ = options
//        _ = request
//        let errorDescription = CoreMLPluginErrorString.operationNotSupported.errorDescription
//        let recovery = CoreMLPluginErrorString.operationNotSupported.recoverySuggestion
//        let predictionsError = PredictionsError.service(errorDescription, recovery, nil)
//        throw predictionsError
//
//        // TODO: Dispatch to Hub???
//        // dispatch(result: .failure(predictionsError))
//    }
//
//    public func convert(
//        speechToText: URL,
//        options: PredictionsSpeechToTextRequest.Options?,
//        onEvent: @escaping (Event) -> Void
//    ) async throws -> SpeechToTextResult {
//        let options = options ?? PredictionsSpeechToTextRequest.Options()
//        let request = PredictionsSpeechToTextRequest(speechToText: speechToText, options: options)
//        let result = try await coreMLSpeech.getTranscription(
//            request.speechToText
//        )
//
//        guard let result = result else {
//            let errorDescription = CoreMLPluginErrorString.transcriptionNoResult.errorDescription
//            let recovery = CoreMLPluginErrorString.transcriptionNoResult.recoverySuggestion
//            let predictionsError = PredictionsError.service(errorDescription, recovery, nil)
//            // TODO: Dispatch to Hub???
//            // self.dispatch(result: .failure(predictionsError))
//            throw predictionsError
//        }
//        return result
//
//        // TODO: Dispatch to Hub???
//        // self.dispatch(result: .success(result))
//    }

//    public func identify(
//        type: IdentifyAction,
//        image: URL,
//        options: PredictionsIdentifyRequest.Options?
//    ) async throws -> IdentifyResult
