//
//  AWSPredictionsService+Polly.swift
//  AWSPredictionsPlugin
//
//  Created by Stone, Nicki on 11/14/19.
//  Copyright © 2019 Amazon Web Services. All rights reserved.
//

import Foundation
import Amplify
import AWSPolly

extension AWSPredictionsService: AWSPollyServiceBehavior {

    func synthesizeText(text: String, onEvent: @escaping AWSPredictionsService.TextToSpeechServiceEventHandler) {
        let request: AWSPollySynthesizeSpeechInput = AWSPollySynthesizeSpeechInput()
        request.text = text
        request.voiceId = .justin
        request.outputFormat = .mp3
        request.textType = .text
        request.sampleRate = "24000"
        request.engine = .neural
        request.languageCode = .enUS

        awsPolly.synthesizeSpeech(request: request).continueWith { (task) -> Any? in

            guard task.error == nil else {
                onEvent(.failed(.networkError(task.error!.localizedDescription, task.error!.localizedDescription)))
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
