//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify

public class AWSTranscribeOperation: AmplifyOperation<
    PredictionsSpeechToTextRequest,
    SpeechToTextResult,
    PredictionsError
>, PredictionsSpeechToTextOperation {

    let multiService: TranscribeMultiService
    let requestInProcess: Bool

    init(request: PredictionsSpeechToTextRequest,
         multiService: TranscribeMultiService,
         requestInProcess: Bool,
         resultListener: ResultListener?) {
        self.multiService = multiService
        self.requestInProcess = requestInProcess
        super.init(categoryType: .predictions,
                   eventName: HubPayload.EventName.Predictions.speechToText,
                   request: request,
                   resultListener: resultListener)
    }

    override public func main() {
        if isCancelled {
             finish()
             return
         }

        if requestInProcess {
            let error = PredictionsError.network(
                "There is already a transcription request in process.",
                "Please wait for that to finish before calling another transcription request"
            )
            dispatch(result: .failure(error))
            finish()
            return
        }

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

    private func onServiceEvent(event: PredictionsEvent<SpeechToTextResult, PredictionsError>) {

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
