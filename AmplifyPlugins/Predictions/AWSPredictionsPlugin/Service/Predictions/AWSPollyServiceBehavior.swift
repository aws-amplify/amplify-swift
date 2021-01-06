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

    typealias TextToSpeechServiceEventHandler = (TextToSpeechServiceEvent) -> Void
    typealias TextToSpeechServiceEvent = PredictionsEvent<TextToSpeechResult, PredictionsError>

    func synthesizeText(text: String,
                        voiceId: AWSPollyVoiceId,
                        onEvent: @escaping TextToSpeechServiceEventHandler)
}
