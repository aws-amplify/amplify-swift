//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify
import AWSPolly

protocol AWSPollyServiceBehavior {
    func synthesizeText(
        text: String,
        voiceId: PollyClientTypes.VoiceId
    ) async throws -> Predictions.Convert.TextToSpeech.Result
}
