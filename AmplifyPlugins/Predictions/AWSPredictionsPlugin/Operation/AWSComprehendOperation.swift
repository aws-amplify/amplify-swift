//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify
import AWSPluginsCore

public class AWSComprehendOperation: AmplifyOperation<PredictionsInterpretRequest,
    Void,
    InterpretResult,
    PredictionsError>,
PredictionsInterpretOperation {

    weak var predictionsService: AWSPredictionsService?
    weak var authService: AWSAuthServiceBehavior?

    init(_ request: PredictionsInterpretRequest,
         predictionsService: AWSPredictionsService,
         authService: AWSAuthServiceBehavior,
         listener: EventListener?) {

        self.predictionsService = predictionsService
        self.authService = authService
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
    }

    private func onServiceEvent(event: PredictionsEvent<InterpretResult, PredictionsError>) {
        switch event {
        case .completed(let result):
            dispatch(event: .completed(result))
            finish()
        case .failed(let error):
            dispatch(event: .failed(error))
            finish()
        }
    }

}
