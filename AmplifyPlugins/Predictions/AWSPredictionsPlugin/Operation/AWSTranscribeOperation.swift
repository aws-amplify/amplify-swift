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

public class AWSTranscribeOperation: AmplifyOperation<PredictionsSpeechToTextRequest,
    Void,
    SpeechToTextResult,
    PredictionsError>,
PredictionsSpeechToTextOperation {

    let multiService: TranscribeMultiService
    let requestInProcess: Bool

    init(request: PredictionsSpeechToTextRequest,
         multiService: TranscribeMultiService,
         requestInProcess: Bool,
         listener: EventListener?) {
        self.multiService = multiService
        self.requestInProcess = requestInProcess
        super.init(categoryType: .predictions,
                   eventName: HubPayload.EventName.Predictions.speechToText,
                   request: request,
                   listener: listener)
    }

    override public func main() {
        if isCancelled {
             finish()
             return
         }

        if requestInProcess {
            let error = PredictionsError.network("There is already a transcription request in process.",
                                                 "Please wait for that to finish before calling another transcription request")
            dispatch(event: .failed(error))
            finish()
            return
        }

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

    private func onServiceEvent(event: PredictionsEvent<SpeechToTextResult, PredictionsError>) {

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
