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

    init(_ request: PredictionsInterpretRequest,
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

    }
}
