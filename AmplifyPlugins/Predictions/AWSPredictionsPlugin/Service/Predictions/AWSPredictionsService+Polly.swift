//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify
import AWSPolly

extension AWSPredictionsService: AWSPollyServiceBehavior {

    func synthesizeText(text: String,
                        voiceId: AWSPollyVoiceId,
                        onEvent: @escaping AWSPredictionsService.TextToSpeechServiceEventHandler) {

        let request: AWSPollySynthesizeSpeechInput = AWSPollySynthesizeSpeechInput()
        request.text = text
        request.voiceId = voiceId
        request.outputFormat = .mp3
        request.textType = .text
        request.sampleRate = "24000"

        awsPolly.synthesizeSpeech(request: request).continueWith { (task) -> Any? in

            guard task.error == nil else {
                let error = task.error! as NSError

                let predictionsErrorString = PredictionsErrorHelper.mapPredictionsServiceError(error)

                onEvent(.failed(
                    .network(predictionsErrorString.errorDescription,
                             predictionsErrorString.recoverySuggestion)))
                return nil
            }

            guard let result = task.result else {
                onEvent(.failed(.unknown("No result was found. An unknown error occurred.", "Please try again.")))
                return nil
            }

            guard let speech = result.audioStream else {
                onEvent(.failed(
                    .network("No result was found.",
                             "Please make sure a text string was sent over to synthesize.")))
                return nil
            }

            let textToSpeechResult = TextToSpeechResult(audioData: speech)

            onEvent(.completed(textToSpeechResult))
            return nil
        }

    }
}
