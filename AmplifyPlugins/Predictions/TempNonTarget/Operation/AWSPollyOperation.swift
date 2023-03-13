//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify
import AWSPolly

public class AWSPollyOperation: AmplifyOperation<
    PredictionsTextToSpeechRequest,
    TextToSpeechResult,
    PredictionsError
>, PredictionsTextToSpeechOperation {

    let predictionsService: AWSPredictionsService

    init(_ request: PredictionsTextToSpeechRequest,
         predictionsService: AWSPredictionsService,
         resultListener: ResultListener?) {
        self.predictionsService = predictionsService
        super.init(categoryType: .predictions,
                   eventName: HubPayload.EventName.Predictions.textToSpeech,
                   request: request,
                   resultListener: resultListener)
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
            dispatch(result: .failure(error))
            finish()
            return
        }

        let voiceId = reconcileVoiceId(voicePassedIn: request.options.voiceType,
                                       config: predictionsService.predictionsConfig)

        predictionsService.synthesizeText(text: request.textToSpeech,
                                          voiceId: voiceId) { [weak self] event in
            self?.onServiceEvent(event: event)
        }

    }

    private func onServiceEvent(event: PredictionsEvent<TextToSpeechResult, PredictionsError>) {
        switch event {
        case .completed(let result):
            dispatch(result: .success(result))
            finish()
        case .failed(let error):
            dispatch(result: .failure(error))
            finish()

        }
    }

    private func reconcileVoiceId(voicePassedIn: VoiceType?,
                                  config: PredictionsPluginConfiguration) -> AWSPollyVoiceId {
        // we return a default if what is passed in doesn't resolve properly to our enum
        // and config was empty for some odd reason.
        let defaultVoiceId = AWSPollyVoiceId.ivy

        if let voicePassedIn = voicePassedIn {
            let pollyVoiceId = AWSPollyVoiceId.from(voiceType: voicePassedIn)
            return pollyVoiceId
        }

        if let pollyVoiceIdFromConfigString = config.convert.speechGenerator?.voiceID {
            let voiceType: VoiceType = .voice(pollyVoiceIdFromConfigString)
            let pollyVoiceIdFromConfig = AWSPollyVoiceId.from(voiceType: voiceType)
            return pollyVoiceIdFromConfig

        }

        return defaultVoiceId
    }
}
