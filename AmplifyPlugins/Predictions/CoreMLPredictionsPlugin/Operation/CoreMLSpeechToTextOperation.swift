//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify

public class CoreMLSpeechToTextOperation: AmplifyOperation<PredictionsSpeechToTextRequest,
    Void,
    SpeechToTextResult,
PredictionsError>, PredictionsSpeechToTextOperation {


    init(_ request: PredictionsSpeechToTextRequest,
         listener: EventListener?) {

        super.init(categoryType: .predictions,
                   eventName: HubPayload.EventName.Predictions.speechToText,
                   request: request,
                   listener: listener)
    }

    override public func main() {
        if isCancelled {
            finish()
            return
        }

        let errorDescription = CoreMLPluginErrorString.operationNotSupported.errorDescription
        let recovery = CoreMLPluginErrorString.operationNotSupported.recoverySuggestion
        let predictionsError = PredictionsError.service(errorDescription, recovery, nil)
        dispatch(event: .failed(predictionsError))
        finish()
    }
}
