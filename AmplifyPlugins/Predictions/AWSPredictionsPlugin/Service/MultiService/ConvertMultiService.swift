//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify
import AWSPolly

class ConvertMultiService: MultiServiceBehavior {

    typealias Event = PredictionsEvent<ConvertResult, PredictionsError>
    typealias ConvertEventHandler = (Event) -> Void

    weak var coreMLService: CoreMLPredictionBehavior?
    weak var predictionsService: AWSPredictionsService?
    var request: PredictionsConvertRequest!

    init(coreMLService: CoreMLPredictionBehavior?,
         predictionsService: AWSPredictionsService?) {
        self.coreMLService = coreMLService
        self.predictionsService = predictionsService
    }

    func setRequest<T: PredictionsConvertRequest>(_ request: T) {
        self.request = request
    }

    func fetchOnlineResult(callback: @escaping ConvertEventHandler) {
        guard let onlineService = predictionsService else {
            let message = ConvertMultiServiceErrorMessage.onlineConvertServiceNotAvailable.errorDescription
            let recoveryMessage = ConvertMultiServiceErrorMessage.onlineConvertServiceNotAvailable.recoverySuggestion
            let predictionError = PredictionsError.service(message, recoveryMessage, nil)
            callback(.failed(predictionError))
            return
        }

        switch request.type {
        case .speechToText:
            if let castedRequest = request as? PredictionsSpeechToTextRequest {
                onlineService.transcribe(speechToText: castedRequest.speechToText, onEvent: callback)
            }
        case .textToSpeech:
            if let castedRequest = request as? PredictionsTextToSpeechRequest {
                let voiceId = reconcileVoiceId(voicePassedIn: castedRequest.options.voiceType,
                                                            config: onlineService.predictionsConfig)
            onlineService.synthesizeText(text: castedRequest.textToSpeech, voiceId: voiceId, onEvent: callback)
            }
        case .translateText:
            if let castedRequest = request as? PredictionsTranslateTextRequest {
            onlineService.translateText(text: castedRequest.textToTranslate,
                                        language: castedRequest.language,
                                        targetLanguage: castedRequest.targetLanguage,
                                        onEvent: callback)
            }

        }
    }

    func fetchOfflineResult(callback: @escaping ConvertEventHandler) {
        guard let offlineService = coreMLService else {
            let message = ConvertMultiServiceErrorMessage.offlineConvertServiceNotAvailable.errorDescription
            let recoveryMessage = ConvertMultiServiceErrorMessage.offlineConvertServiceNotAvailable.recoverySuggestion
            let predictionError = PredictionsError.service(message, recoveryMessage, nil)
            callback(.failed(predictionError))
            return
        }
        guard let castedRequest = request as? PredictionsSpeechToTextRequest else {
            let message = ConvertMultiServiceErrorMessage.inputNotFoundToConvert.errorDescription
            let recoveryMessage = ConvertMultiServiceErrorMessage.inputNotFoundToConvert.recoverySuggestion
            let predictionsError = PredictionsError.service(message, recoveryMessage)
            callback(.failed(predictionsError))
            return
        }
        offlineService.convert(castedRequest.speechToText, type: .speechToText, onEvent: callback)
    }

    // MARK: -
    func mergeResults(offlineResult: ConvertResult?,
                      onlineResult: ConvertResult?,
                      callback: @escaping  ConvertEventHandler) {

        if offlineResult == nil && onlineResult == nil {
            let message = ConvertMultiServiceErrorMessage.noResultConvertService.errorDescription
            let recoveryMessage = ConvertMultiServiceErrorMessage.noResultConvertService.recoverySuggestion
            let predictionError = PredictionsError.service(message, recoveryMessage, nil)
            callback(.failed(predictionError))
            return
        }

        guard let finalOfflineResult = offlineResult else {
            // We are sure that the value will be non-nil at this point.
            callback(.completed(onlineResult!))
            return
        }

        guard let finalOnlineResult = onlineResult else {
            callback(.completed(finalOfflineResult))
            return
        }

        // At this point we decided not to merge the result and return the non-nil online
        // result back.
        callback(.completed(finalOnlineResult))
        return
    }

    private func reconcileVoiceId(voicePassedIn: VoiceType?,
                                  config: PredictionsPluginConfiguration) -> AWSPollyVoiceId {
        //we return a default if what is passed in doesn't resolve properly to our enum and config was empty for some odd reason.
        let defaultVoiceId = AWSPollyVoiceId.ivy

        if let voicePassedIn = voicePassedIn {
            let pollyVoiceId = AWSPollyVoiceId.from(voiceType: voicePassedIn)
            return pollyVoiceId
        }

        if let pollyVoiceIdFromConfigString = config.convert.speechGenerator?.voiceID {
            let voiceType: VoiceType = .voice(pollyVoiceIdFromConfigString)
            let pollyVoiceIdFromConfig = AWSPollyVoiceId.from(voiceType: voiceType)
            return pollyVoiceIdFromConfig

        }

        return defaultVoiceId
    }
}
