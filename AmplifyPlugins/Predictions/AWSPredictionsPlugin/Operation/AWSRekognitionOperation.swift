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


    override public func main() {


        if let error = request.validate() {
                 dispatch(error)
                 finish()
                 return
        }

        let identityIdResult = authService.getIdentityId()

        switch request.identifyType {
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
            dispatch(event: .completed(result))
        case .failed(let error):
            dispatch(event: .failed(error))
            
        }
    }


}
