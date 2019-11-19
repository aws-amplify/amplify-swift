//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify
import AWSMobileClient
import AWSPluginsCore

public class AWSIdentifyOperation: AmplifyOperation<PredictionsIdentifyRequest,
    Void, IdentifyResult, PredictionsError>,
PredictionsIdentifyOperation {

    let predictionsService: AWSPredictionsService
    let authService: AWSAuthServiceBehavior

    init(request: PredictionsIdentifyRequest,
         predictionsService: AWSPredictionsService,
         authService: AWSAuthServiceBehavior,
         listener: EventListener?) {
        self.predictionsService = predictionsService
        self.authService = authService
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

        switch request.identifyType {
        case .detectCelebrity:
            predictionsService.detectCelebrities(image: request.image) { [weak self] event in
                self?.onServiceEvent(event: event)

            }
        case .detectText(let formatType):
            predictionsService.detectText(image: request.image, format: formatType) { [weak self] event in
                self?.onServiceEvent(event: event)
            }
        case .detectLabels(let labelType):
            predictionsService.detectLabels(image: request.image,
                                            type: labelType) { [weak self] event in
                self?.onServiceEvent(event: event)
            }

        case .detectEntities:
            predictionsService.detectEntities(image: request.image) { [weak self] event in
                self?.onServiceEvent(event: event)
            }
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
