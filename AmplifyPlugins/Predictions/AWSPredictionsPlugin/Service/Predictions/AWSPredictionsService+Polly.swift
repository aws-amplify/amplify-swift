//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//


import Foundation
import Amplify
import AWSPolly

extension AWSPredictionsService: AWSPollyServiceBehavior {

    func synthesizeText(text: String,
                        voiceId: VoiceType?,
                        onEvent: @escaping AWSPredictionsService.TextToSpeechServiceEventHandler) {

        guard let voiceFromConfig = VoiceType(voice: predictionsConfig.convertConfig?.voiceId) else {
            onEvent(.failed(
                .networkError("Something was wrong with the voice id from config.",
                              "Make sure a correct value exists in your config file.")))
            return
        }

        let request: AWSPollySynthesizeSpeechInput = AWSPollySynthesizeSpeechInput()
        request.text = text
        //default to what you passed in for options if you passed in anything, if not pull default from config.
        request.voiceId = voiceId?.pollyVoiceType ?? voiceFromConfig.pollyVoiceType
        request.outputFormat = .mp3
        request.textType = .text
        request.sampleRate = "24000"

        awsPolly.synthesizeSpeech(request: request).continueWith { (task) -> Any? in

            guard task.error == nil else {
                let error = task.error! as NSError
                let predictionsErrorString = PredictionsErrorHelper.mapPollyError(error)
                onEvent(.failed(
                    .networkError(predictionsErrorString.errorDescription,
                                  predictionsErrorString.recoverySuggestion)))
                return nil
            }

            guard let result = task.result else {
                onEvent(.failed(.unknownError("No result was found. An unknown error occurred.", "Please try again.")))
                return nil
            }

            guard let speech = result.audioStream else {
                onEvent(.failed(
                    .networkError("No result was found.",
                                  "Please make sure a text string was sent over and that the target language was different from the language sent.")))
                return nil
            }

            let textToSpeechResult = TextToSpeechResult(audioData: speech)

            onEvent(.completed(textToSpeechResult))
            return nil
        }

    }
}
