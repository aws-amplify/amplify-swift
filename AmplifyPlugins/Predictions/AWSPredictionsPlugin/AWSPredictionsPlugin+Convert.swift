//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify
@_spi(PredictionsConvertRequestKind) import Amplify
import AWSPolly

extension AWSPredictionsPlugin {

    ///
    /// - Parameters:
    ///   - request:
    ///   - options:
    /// - Returns: 
    public func convert<Input, Options, Output>(
        _ request: Predictions.Convert.Request<Input, Options, Output>,
        options: Options?
    ) async throws -> Output {
        switch request.kind {
        case let .textToSpeech(lift):
            let input = lift.inputGenericToSpecific(request.input)
            let options = lift.optionsGenericToSpecific(options)
            let result = try await convertTextToSpeech(input, options: options)
            return lift.outputSpecificToGeneric(result)

        case let .speechToText(lift):
            let input = lift.inputGenericToSpecific(request.input)
            let options = lift.optionsGenericToSpecific(options)
            let stream = try await convertSpeechToText(url: input, options: options)
            return lift.outputSpecificToGeneric(stream)

        case let .textToTranslate(lift):
            let (text, fromLanguage, toLanguage) = lift.inputGenericToSpecific(request.input)
            let options = lift.optionsGenericToSpecific(options)
            let result = try await convertTextToTranslate(
                text,
                fromLanguage: fromLanguage,
                toLanguage: toLanguage,
                options: options
            )

            return lift.outputSpecificToGeneric(result)
        }
    }

    private func convertTextToSpeech(
        _ text: String,
        options: Predictions.Convert.TextToSpeech.Options?
    ) async throws -> Predictions.Convert.TextToSpeech.Result {
        let request = Predictions.Convert.TextToSpeech.Request(
            textToSpeech: text,
            options: options ?? .init()
        )

        let voiceID = reconcileVoiceID(
            voice: request.options.voice,
            config: predictionsService.predictionsConfig
        )

        let result = try await predictionsService.synthesizeText(
            text: request.textToSpeech,
            voiceId: voiceID
        )

        return result
    }

    private func convertSpeechToText(
        url: URL,
        options: Predictions.Convert.SpeechToText.Options?
    ) async throws -> AsyncThrowingStream<Predictions.Convert.SpeechToText.Result, Error> {
        let stream = try await predictionsService.transcribe(
            speechToText: url,
            language: options?.language,
            region: "us-east-1"
        )

        return stream
    }

    private func convertTextToTranslate(
        _ text: String,
        fromLanguage: Predictions.Language?,
        toLanguage: Predictions.Language?,
        options: Predictions.Convert.TranslateText.Options?
    ) async throws -> Predictions.Convert.TranslateText.Result {
        let request = Predictions.Convert.TranslateText.Request(
            textToTranslate: text,
            targetLanguage: toLanguage,
            language: fromLanguage,
            options: options ?? .init()
        )

        let result = try await predictionsService.translateText(
            text: request.textToTranslate,
            language: request.language,
            targetLanguage: request.targetLanguage
        )
        return result
    }

    private func reconcileVoiceID(
        voice: Predictions.Voice?,
        config: PredictionsPluginConfiguration
    ) -> PollyClientTypes.VoiceId {
        if let voice = voice,
           let pollyVoiceID = PollyClientTypes.VoiceId(rawValue: voice.id) {
            return pollyVoiceID
        }

        if let configVoice = config.convert.speechGenerator?.voiceID,
           let pollyVoiceID = PollyClientTypes.VoiceId(rawValue: configVoice) {
            return pollyVoiceID
        }

        let defaultVoiceID = PollyClientTypes.VoiceId.ivy
        return defaultVoiceID
    }
}
