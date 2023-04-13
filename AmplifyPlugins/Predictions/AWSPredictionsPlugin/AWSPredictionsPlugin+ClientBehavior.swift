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

    public func identify<Output>(
        _ request: Predictions.Identify.Request<Output>,
        in image: URL,
        options: Predictions.Identify.Options?
    ) async throws -> Output {
        let multiService = IdentifyMultiService(
            request: request,
            url: image,
            coreMLService: coreMLService,
            predictionsService: predictionsService
        )

        let options = options ?? .init()
        switch options.defaultNetworkPolicy {
        case .offline:
            let offlineResult = try await multiService.offlineResult()
            return offlineResult
        case .auto:
            let online = try await multiService.onlineResult()
            return online
//            let offline = try await multiService.offlineResult()
//            let merged = multiService.mergeResults(
//                offline: offline,
//                online: online
//            )
//            return merged
        }
    }

    private func convertTextToSpeech(
        _ text: String,
        options: PredictionsTextToSpeechRequest.Options?
    ) async throws -> TextToSpeechResult {
        let request = PredictionsTextToSpeechRequest(
            textToSpeech: text,
            options: options ?? .init()
        )

        try request.validate()

        func reconcileVoiceID(
            voice: VoiceType?,
            config: PredictionsPluginConfiguration
        ) -> PollyClientTypes.VoiceId {
            if case .voice(let voice) = request.options.voiceType,
               let pollyVoiceID = PollyClientTypes.VoiceId(rawValue: voice) {
                return pollyVoiceID
            }

            if let configVoice = config.convert.speechGenerator?.voiceID,
               let pollyVoiceID = PollyClientTypes.VoiceId(rawValue: configVoice) {
                return pollyVoiceID
            }

            let defaultVoiceID = PollyClientTypes.VoiceId.ivy
            return defaultVoiceID
        }

        let voiceID = reconcileVoiceID(
            voice: request.options.voiceType,
            config: predictionsService.predictionsConfig
        )

        let result = try await predictionsService.synthesizeText(
            text: request.textToSpeech,
            voiceId: voiceID
        )

        return result
    }

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
            let stream = convertSpeechToText(url: input, options: options)
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

    private func convertSpeechToText(
        url: URL,
        options: PredictionsSpeechToTextRequest.Options?
    ) -> AsyncThrowingStream<SpeechToTextResult, Error> {

        let stream = AsyncThrowingStream<SpeechToTextResult, Error> { continuation in
            Task {
                try await transcribe(
                    speechToText: url,
                    options: options,
                    region: "us-east-1",
                    handler: { result in
                        continuation.yield(result)
                    }
                )
            }
        }
        return stream
    }

    private func convertTextToTranslate(
        _ text: String,
        fromLanguage: LanguageType?,
        toLanguage: LanguageType?,
        options: PredictionsTranslateTextRequest.Options?
    ) async throws -> TranslateTextResult {
        let request = PredictionsTranslateTextRequest(
            textToTranslate: text,
            targetLanguage: toLanguage,
            language: fromLanguage,
            options: options ?? PredictionsTranslateTextRequest.Options()
        )

        let result = try await predictionsService.translateText(
            text: request.textToTranslate,
            language: request.language,
            targetLanguage: request.targetLanguage
        )
        return result
    }

    /// Interprets the input text and detects sentiment, language, syntax, and key phrases
    ///
    /// - Parameter text: input text
    /// - Parameter options: Option for the plugin
    /// - Parameter resultListener: Listener to which events are send
    public func interpret(
        text: String,
        options: Predictions.Interpret.Options?
    ) async throws -> Predictions.Interpret.Result {
//        let request = Predictions.Interpret.Request(
//            textToInterpret: text,
//            options: options ?? Predictions.Interpret.Options()
//        )

        let options = options ?? .init()
        let multiService = InterpretTextMultiService(
            coreMLService: coreMLService,
            predictionsService: predictionsService
        )

        multiService.setTextToInterpret(text: text)  //request.textToInterpret)
        switch options.defaultNetworkPolicy {
        case .offline:
            let offlineResposne = try await multiService.fetchOfflineResult()
            return offlineResposne
        case .auto:
            let multiServiceResposne = try await multiService.fetchMultiServiceResult()
            return multiServiceResposne
        }
    }
}



//    public func convert(
//        textToTranslate: String,
//        language: LanguageType?,
//        targetLanguage: LanguageType?,
//        options: PredictionsTranslateTextRequest.Options?
//    ) async throws -> TranslateTextResult {
//        let request = PredictionsTranslateTextRequest(
//            textToTranslate: textToTranslate,
//            targetLanguage: targetLanguage,
//            language: language,
//            options: options ?? PredictionsTranslateTextRequest.Options()
//        )
//
//        return try await predictionsService.translateText(
//            text: request.textToTranslate,
//            language: request.language,
//            targetLanguage: request.targetLanguage
//        )
//    }
//
//    public func convert(
//        textToSpeech: String,
//        options: PredictionsTextToSpeechRequest.Options?
//    ) async throws -> TextToSpeechResult {
//        let request = PredictionsTextToSpeechRequest(
//            textToSpeech: textToSpeech,
//            options: options ?? PredictionsTextToSpeechRequest.Options()
//        )
//
//        try request.validate()
//
//        func reconcileVoiceID(
//            voice: VoiceType?,
//            config: PredictionsPluginConfiguration
//        ) -> PollyClientTypes.VoiceId {
//            if case .voice(let voice) = request.options.voiceType,
//               let pollyVoiceID = PollyClientTypes.VoiceId(rawValue: voice) {
//                return pollyVoiceID
//            }
//
//            if let configVoice = config.convert.speechGenerator?.voiceID,
//               let pollyVoiceID = PollyClientTypes.VoiceId(rawValue: configVoice) {
//                return pollyVoiceID
//            }
//
//            let defaultVoiceID = PollyClientTypes.VoiceId.ivy
//            return defaultVoiceID
//        }
//
//        let voiceID = reconcileVoiceID(
//            voice: request.options.voiceType,
//            config: predictionsService.predictionsConfig
//        )
//
//        let result = try await predictionsService.synthesizeText(
//            text: request.textToSpeech,
//            voiceId: voiceID
//        )
//
//        return result
//    }
//
//
//    public func convert(
//        speechToText: URL,
//        options: PredictionsSpeechToTextRequest.Options?,
//        onEvent: @escaping (Event) -> Void
//    ) async throws -> SpeechToTextResult {
//
//        try await transcribe(
//            speechToText: speechToText,
//            options: options,
//            region: "us-east-1",
//            onEvent: onEvent
//        )
//
//
//        if #available(iOS 16.0, *) {
//            print("sleeping")
//            try await Task.sleep(for: .seconds(10))
//        }
//        print("returning")
//        return .init(transcription: "hello world")
//
//        // TODO: Transcribe
////        let request = PredictionsSpeechToTextRequest(
////            speechToText: speechToText,
////            options: options ?? PredictionsSpeechToTextRequest.Options()
////        )
////
////        let multiService = TranscribeMultiService(
////            coreMLService: coreMLService,
////            predictionsService: predictionsService
////        )
////
//        // TODO: Only one transcription request can be sent at a time otherwise you receive an error
////        throw NSError(domain: "", code: 42, userInfo: nil)
//    }

//    public func identify(
//        type: IdentifyAction,
//        image: URL,
//        options: PredictionsIdentifyRequest.Options?
//    ) async throws -> IdentifyResult
