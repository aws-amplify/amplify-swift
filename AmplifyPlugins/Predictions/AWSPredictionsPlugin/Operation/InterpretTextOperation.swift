//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify
import AWSPluginsCore

public class InterpretTextOperation: AmplifyOperation<PredictionsInterpretRequest,
    Void,
    InterpretResult,
    PredictionsError>,
PredictionsInterpretOperation {

    let multiService: InterpretTextMultiService

    init(_ request: PredictionsInterpretRequest,
         multiService: InterpretTextMultiService,
         listener: EventListener?) {

        self.multiService = multiService
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
        multiService.setTextToInterpret(text: request.textToInterpret)
        switch request.options.defaultNetworkPolicy {
        case .offline:
            multiService.fetchOfflineResult(callback: { event in
                self.onServiceEvent(event: event)
            })
        case .auto:
            multiService.fetchMultiServiceResult(callback: { event in
                self.onServiceEvent(event: event)
            })
        }
    }

    // MARK: -

    private func onServiceEvent(event: PredictionsEvent<InterpretResult, PredictionsError>) {

        if isCancelled {
            finish()
            return
        }

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
