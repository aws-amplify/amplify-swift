//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify
import AWSMobileClient

public class AWSTranslateOperation: AmplifyOperation<PredictionsTranslateTextRequest, Void, TranslateTextResult, PredictionsError>,
PredictionsTranslateTextOperation {

    let translateService: AWSTranslateServiceBehaviour
    let authService: AWSAuthServiceBehavior

    init(_ request: PredictionsTranslateTextRequest,
         translateService: AWSTranslateServiceBehaviour,
         authService: AWSAuthServiceBehavior,
         listener: EventListener?) {
        self.translateService = translateService
        self.authService = authService
        super.init(categoryType: .predictions,
                   eventName: HubPayload.EventName.Predictions.translate,
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
        translateService.translateText(text: request.textToTranslate, language: request.language, targetLanguage: request.targetLanguage) { [weak self] event in
            self?.onServiceEvent(event: event)

        }
    }

    private func onServiceEvent(event: PredictionsEvent<TranslateTextResult, PredictionsError>) {
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
    private func dispatch(_ result: TranslateTextResult) {
        let asyncEvent = AsyncEvent<Void, TranslateTextResult, PredictionsError>.completed(result)
        dispatch(event: asyncEvent)

    }

    private func dispatch(_ error: PredictionsError) {
        let asyncEvent = AsyncEvent<Void, TranslateTextResult, PredictionsError>.failed(error)
        dispatch(event: asyncEvent)
    }

}
