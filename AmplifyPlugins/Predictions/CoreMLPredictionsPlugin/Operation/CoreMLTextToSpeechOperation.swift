//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify

public class CoreMLTextToSpeechOperation: AmplifyOperation<PredictionsTextToSpeechRequest,
    Void,
    TextToSpeechResult,
PredictionsError>, PredictionsTextToSpeechOperation {


    init(_ request: PredictionsTextToSpeechRequest,
         listener: EventListener?) {

        super.init(categoryType: .predictions,
                   eventName: HubPayload.EventName.Predictions.textToSpeech,
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
