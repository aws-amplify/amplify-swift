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

    func synthesizeText(
        text: String,
        voiceId: PollyClientTypes.VoiceId
    ) async throws -> Predictions.Convert.TextToSpeech.Result {

        let input = SynthesizeSpeechInput(
            outputFormat: .mp3,
            sampleRate: "24000",
            text: text,
            textType: .text,
            voiceId: voiceId
        )
        let synthesizedSpeechResult = try await awsPolly.synthesizeSpeech(input: input)

        guard let speech = synthesizedSpeechResult.audioStream
        else {
            throw PredictionsError.service(
                "No result was found.",
                "Please make sure a text string was sent over to synthesize."
            )
        }

        let textToSpeechResult = Predictions.Convert.TextToSpeech.Result(
            audioData: speech.toBytes().toData()
        )

        return textToSpeechResult
    }
}
