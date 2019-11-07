//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify

public class CoreMLInterpretTextOperation: AmplifyOperation<PredictionsInterpretRequest,
    Void,
    InterpretResult,
PredictionsError>, PredictionsInterpretOperation {

    let coreMLNaturalLanguage: CoreMLNaturalLanguageBehavior

    init(_ request: PredictionsInterpretRequest,
         coreMLNaturalLanguage: CoreMLNaturalLanguageBehavior,
         listener: EventListener?) {

        self.coreMLNaturalLanguage = coreMLNaturalLanguage
        super.init(categoryType: .predictions,
                   eventName: HubPayload.EventName.Predictions.interpret,
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
        let dominantLanguage = coreMLNaturalLanguage.detectDominantLanguage(for: request.textToInterpret)

    }
}
