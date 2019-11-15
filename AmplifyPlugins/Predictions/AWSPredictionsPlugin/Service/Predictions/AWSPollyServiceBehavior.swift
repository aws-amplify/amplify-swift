//
//  AWSPollyServiceBehavior.swift
//  AWSPredictionsPlugin
//
//  Created by Stone, Nicki on 11/14/19.
//  Copyright © 2019 Amazon Web Services. All rights reserved.
//

import Foundation
import Amplify
import AWSPolly

protocol AWSPollyServiceBehavior {

    typealias TextToSpeechServiceEventHandler = (TextToSpeechServiceEvent) -> Void
    typealias TextToSpeechServiceEvent = PredictionsEvent<TextToSpeechResult, PredictionsError>

    func synthesizeText(text: String,
                        voiceId: VoiceType?,
                        onEvent: @escaping TextToSpeechServiceEventHandler)
}
