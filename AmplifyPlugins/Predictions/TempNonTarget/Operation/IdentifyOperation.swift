//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify

public class IdentifyOperation: AmplifyOperation<
    PredictionsIdentifyRequest,
    IdentifyResult,
    PredictionsError
>, PredictionsIdentifyOperation {

    let multiService: IdentifyMultiService

    init(request: PredictionsIdentifyRequest,
         multiService: IdentifyMultiService,
         resultListener: ResultListener?) {
        self.multiService = multiService
        super.init(categoryType: .predictions,
                   eventName: HubPayload.EventName.Predictions.identifyLabels,
                   request: request,
                   resultListener: resultListener)
    }

    override public func main() {

        if let error = request.validate() {
            dispatch(result: .failure(error))
            finish()
            return
        }
        multiService.setRequest(request)
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

    private func onServiceEvent(event: PredictionsEvent<IdentifyResult, PredictionsError>) {
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
