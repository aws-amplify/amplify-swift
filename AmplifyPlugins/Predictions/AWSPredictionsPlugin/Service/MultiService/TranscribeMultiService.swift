//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify
import AWSPolly

class TranscribeMultiService: MultiServiceBehavior {

    typealias Event = PredictionsEvent<SpeechToTextResult, PredictionsError>
    typealias ConvertEventHandler = (Event) -> Void

    weak var coreMLService: CoreMLPredictionBehavior?
    weak var predictionsService: AWSPredictionsService?
    var request: PredictionsSpeechToTextRequest!

    init(coreMLService: CoreMLPredictionBehavior?,
         predictionsService: AWSPredictionsService?) {
        self.coreMLService = coreMLService
        self.predictionsService = predictionsService
    }

    func setRequest(_ request: PredictionsSpeechToTextRequest) {
        self.request = request
    }

    func fetchOnlineResult(callback: @escaping ConvertEventHandler) {
        guard let onlineService = predictionsService else {
            let message = ConvertMultiServiceErrorMessage.onlineConvertServiceNotAvailable.errorDescription
            let recoveryMessage = ConvertMultiServiceErrorMessage.onlineConvertServiceNotAvailable.recoverySuggestion
            let predictionError = PredictionsError.service(message, recoveryMessage, nil)
            callback(.failed(predictionError))
            return
        }

        onlineService.transcribe(speechToText: request.speechToText,
                                 language: request.options.language,
                                 onEvent: callback)
    }

    func fetchOfflineResult(callback: @escaping ConvertEventHandler) {
        guard let offlineService = coreMLService else {
            let message = ConvertMultiServiceErrorMessage.offlineConvertServiceNotAvailable.errorDescription
            let recoveryMessage = ConvertMultiServiceErrorMessage.offlineConvertServiceNotAvailable.recoverySuggestion
            let predictionError = PredictionsError.service(message, recoveryMessage, nil)
            callback(.failed(predictionError))
            return
        }
        offlineService.transcribe(request.speechToText, onEvent: callback)
    }

    // MARK: -
    func mergeResults(offlineResult: SpeechToTextResult?,
                      onlineResult: SpeechToTextResult?,
                      callback: @escaping  ConvertEventHandler) {

        if offlineResult == nil && onlineResult == nil {
            let message = ConvertMultiServiceErrorMessage.noResultConvertService.errorDescription
            let recoveryMessage = ConvertMultiServiceErrorMessage.noResultConvertService.recoverySuggestion
            let predictionError = PredictionsError.service(message, recoveryMessage, nil)
            callback(.failed(predictionError))
            return
        }

        guard let finalOfflineResult = offlineResult else {
            // We are sure that the value will be non-nil at this point.
            callback(.completed(onlineResult!))
            return
        }

        guard let finalOnlineResult = onlineResult else {
            callback(.completed(finalOfflineResult))
            return
        }

        // At this point we decided not to merge the result and return the non-nil online
        // result back.
        callback(.completed(finalOnlineResult))
        return
    }
}
