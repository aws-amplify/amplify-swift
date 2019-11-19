//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify

public class CoreMLIdentifyOperation: AmplifyOperation<PredictionsIdentifyRequest,
    Void,
    IdentifyResult,
PredictionsError>, PredictionsIdentifyOperation {

    weak var coreMLVision: CoreMLVisionBehavior?

    init(_ request: PredictionsIdentifyRequest,
         coreMLVision: CoreMLVisionBehavior,
         listener: EventListener?) {

        self.coreMLVision = coreMLVision
        super.init(categoryType: .predictions,
                   eventName: HubPayload.EventName.Predictions.identifyLabels,
                   request: request,
                   listener: listener)
    }

    override public func cancel() {
        super.cancel()
    }

    override public func main() {

        guard let coreMLVisionAdapter = coreMLVision else {
            finish()
            return
        }

        if isCancelled {
            finish()
            return
        }
        switch request.identifyType {
        case .detectCelebrity, .detectEntities:
            fatalError()
        case .detectText:
            guard  let result = coreMLVisionAdapter.detectText(request.image) else {
                return
            }
            dispatch(event: .completed(result))
            finish()
        case .detectLabels:
            guard  let result = coreMLVisionAdapter.detectLabels(request.image) else {
                return
            }
            dispatch(event: .completed(result))
            finish()
        }

        finish()
    }
}
