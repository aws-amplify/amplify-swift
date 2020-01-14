//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify

public class CoreMLSpeechToTextOperation: AmplifyOperation<PredictionsConvertRequest,
    Void,
    ConvertResult,
PredictionsError>, PredictionsConvertOperation {

       weak var coreMLSpeech: CoreMLSpeechBehavior?

    init(_ request: PredictionsSpeechToTextRequest,
         coreMLSpeech: CoreMLSpeechBehavior,
         listener: EventListener?) {

        self.coreMLSpeech = coreMLSpeech
        super.init(categoryType: .predictions,
                   eventName: HubPayload.EventName.Predictions.convert,
                   request: request,
                   listener: listener)
    }

    override public func main() {
        guard let coreMLSpeechAdapter = coreMLSpeech else {
            finish()
            return
        }

        if isCancelled {
            finish()
            return
        }

        switch request.type {
        case .speechToText:
            guard let request = request as? PredictionsSpeechToTextRequest else {
                let errorDescription = CoreMLPluginErrorString.requestObjectExpected.errorDescription
                let recovery = CoreMLPluginErrorString.requestObjectExpected.recoverySuggestion
                let predictionsError = PredictionsError.service(errorDescription, recovery)
                dispatch(event: .failed(predictionsError))
                finish()
                return
            }

            guard let result = coreMLSpeechAdapter.getTranscription(request.speechToText) else {
                let errorDescription = CoreMLPluginErrorString.transcriptionNoResult.errorDescription
                let recovery = CoreMLPluginErrorString.transcriptionNoResult.recoverySuggestion
                let predictionsError = PredictionsError.service(errorDescription, recovery, nil)
                dispatch(event: .failed(predictionsError))
                finish()
                return
            }
            dispatch(event: .completed(result))
            finish()
        case .textToSpeech:
            let errorDescription = CoreMLPluginErrorString.operationNotSupported.errorDescription
            let recovery = CoreMLPluginErrorString.operationNotSupported.recoverySuggestion
            let predictionsError = PredictionsError.service(errorDescription, recovery, nil)
            dispatch(event: .failed(predictionsError))
            finish()
        case .translateText:
            let errorDescription = CoreMLPluginErrorString.operationNotSupported.errorDescription
            let recovery = CoreMLPluginErrorString.operationNotSupported.recoverySuggestion
            let predictionsError = PredictionsError.service(errorDescription, recovery, nil)
            dispatch(event: .failed(predictionsError))
            finish()
        }


    }
}
