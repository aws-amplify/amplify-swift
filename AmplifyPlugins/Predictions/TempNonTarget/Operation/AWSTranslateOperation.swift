//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify

public class AWSTranslateOperation: AmplifyOperation<
    PredictionsTranslateTextRequest,
    TranslateTextResult,
    PredictionsError
>, PredictionsTranslateTextOperation {

    let predictionsService: AWSPredictionsService

    init(_ request: PredictionsTranslateTextRequest,
         predictionsService: AWSPredictionsService,
         resultListener: ResultListener?) {
        self.predictionsService = predictionsService
        super.init(categoryType: .predictions,
                   eventName: HubPayload.EventName.Predictions.translate,
                   request: request,
                   resultListener: resultListener)
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
            dispatch(result: .failure(error))
            finish()
            return
        }

        predictionsService.translateText(text: request.textToTranslate,
                                         language: request.language,
                                         targetLanguage: request.targetLanguage) { [weak self] event in
                                            self?.onServiceEvent(event: event)

        }
    }

    private func onServiceEvent(event: PredictionsEvent<TranslateTextResult, PredictionsError>) {
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
