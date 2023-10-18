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

        do {
            let synthesizedSpeechResult = try await awsPolly.synthesizeSpeech(input: input)
            guard let speech = try await synthesizedSpeechResult.audioStream?.readData()
            else {
                throw PredictionsError.service(
                    .init(
                        description: "No result was found.",
                        recoverySuggestion: "Please make sure a text string was sent over to synthesize."
                    )
                )
            }

            return .init(audioData: speech)
        } catch let error as PredictionsErrorConvertible {
            throw error.predictionsError
        } catch {
            throw PredictionsError.unexpectedServiceErrorType(error)
        }
    }
}
