//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify

public class InterpretTextOperation: AmplifyOperation<
    PredictionsInterpretRequest,
    InterpretResult,
    PredictionsError
>, PredictionsInterpretOperation {

    let multiService: InterpretTextMultiService

    init(_ request: PredictionsInterpretRequest,
         multiService: InterpretTextMultiService,
         resultListener: ResultListener?) {

        self.multiService = multiService
        super.init(categoryType: .predictions,
                   eventName: HubPayload.EventName.Predictions.interpret,
                   request: request,
                   resultListener: resultListener)
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
            dispatch(result: .success(result))
            finish()
        case .failed(let error):
            dispatch(result: .failure(error))
            finish()
        }
    }

}
