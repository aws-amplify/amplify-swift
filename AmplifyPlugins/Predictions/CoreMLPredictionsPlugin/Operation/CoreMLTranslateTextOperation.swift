//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify

public class CoreMLTranslateTextOperation: AmplifyOperation<PredictionsTranslateTextRequest,
    Void,
    TranslateTextResult,
PredictionsError>, PredictionsTranslateTextOperation {


    init(_ request: PredictionsTranslateTextRequest,
         listener: EventListener?) {

        super.init(categoryType: .predictions,
                   eventName: HubPayload.EventName.Predictions.interpret,
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
