//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify
import AWSMobileClient
import AWSPluginsCore

public class IdentifyOperation: AmplifyOperation<PredictionsIdentifyRequest,
    Void,
    IdentifyResult,
    PredictionsError>,
PredictionsIdentifyOperation {

    let multiService: IdentifyMultiService

    init(request: PredictionsIdentifyRequest,
         multiService: IdentifyMultiService,
         listener: EventListener?) {
        self.multiService = multiService
        super.init(categoryType: .predictions,
                   eventName: HubPayload.EventName.Predictions.identifyLabels,
                   request: request,
                   listener: listener)
    }

    override public func main() {

        if let error = request.validate() {
            dispatch(event: .failed(error))
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
            dispatch(event: .completed(result))
            finish()
        case .failed(let error):
            dispatch(event: .failed(error))
            finish()
        }
    }
}
