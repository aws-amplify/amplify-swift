//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify
import AWSMobileClient

public class AWSRekognitionOperation: AmplifyOperation<PredictionsIdentifyRequest, Void, IdentifyResult, PredictionsError>,
PredictionsIdentifyOperation {

    let rekognitionService: AWSRekognitionServiceBehaviour
    let authService: AWSAuthServiceBehavior

    init(_ request: PredictionsIdentifyRequest,
         rekognitionService: AWSRekognitionServiceBehaviour,
         authService: AWSAuthServiceBehavior,
         listener: EventListener?) {
        self.rekognitionService = rekognitionService
        self.authService = authService
        super.init(categoryType: .predictions,
                   eventName: HubPayload.EventName.Predictions.identifyLabels,
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

        if let error = request.validate() {
                 dispatch(error)
                 finish()
                 return
        }

        let identityIdResult = authService.getIdentityId()

        switch (request.identifyType) {
        case .detectCelebrity:
            break
        case .detectText:
            break
        case .detectLabels:
            rekognitionService.detectLabels(
            image: request.image) { [weak self] event in
                self?.onServiceEvent(event: event)
            }

        case .detectEntities:
            break
        }
    }

    private func onServiceEvent(event: PredictionsEvent<IdentifyResult, PredictionsError>) {
        switch event {
        case .completed(let result):
            dispatch(result)
            finish()
        case .failed(let error):
            dispatch(error)
            finish()
        default:
            break
        }
    }
    private func dispatch(_ result: IdentifyResult) {
        let asyncEvent = AsyncEvent<Void, IdentifyResult, PredictionsError>.completed(result)
        dispatch(event: asyncEvent)

    }

    private func dispatch(_ error: PredictionsError) {
        let asyncEvent = AsyncEvent<Void, IdentifyResult, PredictionsError>.failed(error)
        dispatch(event: asyncEvent)
    }

}
