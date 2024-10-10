//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import AWSPolly
import Foundation

protocol AWSPollyServiceBehavior {
    func synthesizeText(
        text: String,
        voiceId: PollyClientTypes.VoiceId
    ) async throws -> Predictions.Convert.TextToSpeech.Result
}
