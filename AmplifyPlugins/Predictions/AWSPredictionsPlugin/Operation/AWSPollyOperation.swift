//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify
import AWSPluginsCore
import AWSPolly

public class AWSPollyOperation: AmplifyOperation<PredictionsTextToSpeechRequest,
    Void, TextToSpeechResult, PredictionsError>,
PredictionsTextToSpeechOperation {

    let predictionsService: AWSPredictionsService
    let authService: AWSAuthServiceBehavior

    init(_ request: PredictionsTextToSpeechRequest,
         predictionsService: AWSPredictionsService,
         authService: AWSAuthServiceBehavior,
         listener: EventListener?) {
        self.predictionsService = predictionsService
        self.authService = authService
        super.init(categoryType: .predictions,
                   eventName: HubPayload.EventName.Predictions.textToSpeech,
                   request: request,
                   listener: listener)
    }

    override public func cancel() {
        super.cancel()
    }

    override public func main() {
        if isCancelled {
            finish()
            return
        }

        if let error = try? request.validate() {
            dispatch(event: .failed(error))
            finish()
            return
        }

        let voiceId = reconcileVoiceId(voicePassedIn: request.options.voiceType, config: predictionsService.predictionsConfig)
        predictionsService.synthesizeText(text: request.textToSpeech,
                                          voiceId: voiceId) { [weak self] event in
            self?.onServiceEvent(event: event)
        }

    }

    private func onServiceEvent(event: PredictionsEvent<TextToSpeechResult, PredictionsError>) {
        switch event {
        case .completed(let result):
            dispatch(event: .completed(result))
            finish()
        case .failed(let error):
            dispatch(event: .failed(error))
            finish()

        }
    }

    private func reconcileVoiceId(voicePassedIn: VoiceType?, config: AWSPredictionsPluginConfiguration) -> AWSPollyVoiceId {
        //we return a default if what is passed in doesn't resolve properly to our enum and config was empty for some odd reason.
        let defaultVoiceId = AWSPollyVoiceId.ivy

        if let voicePassedIn = voicePassedIn,
            let pollyVoiceId = try? AWSPollyVoiceId.from(voiceType: voicePassedIn) {
                   return pollyVoiceId
        }

        if let pollyVoiceIdFromConfigString = config.convertConfig?.voiceId {
            let voiceType: VoiceType = .voice(pollyVoiceIdFromConfigString)
            if let pollyVoiceIdFromConfig = try? AWSPollyVoiceId.from(voiceType: voiceType) {
                return pollyVoiceIdFromConfig
            }
        }

        return defaultVoiceId
    }

}
