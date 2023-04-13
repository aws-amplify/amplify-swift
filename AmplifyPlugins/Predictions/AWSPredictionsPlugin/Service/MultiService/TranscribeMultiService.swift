//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//
// TODO: Transcribe


//import Foundation
//import Amplify
//import AWSPolly
//
//class TranscribeMultiService: MultiServiceBehavior {
//
//    typealias Event = PredictionsEvent<SpeechToTextResult, PredictionsError>
//    typealias ConvertEventHandler = (Event) -> Void
//
//    weak var coreMLService: CoreMLPredictionBehavior?
//    weak var predictionsService: AWSPredictionsService?
//    var request: PredictionsSpeechToTextRequest!
//
//    init(coreMLService: CoreMLPredictionBehavior?,
//         predictionsService: AWSPredictionsService?) {
//        self.coreMLService = coreMLService
//        self.predictionsService = predictionsService
//    }
//
//    func setRequest(_ request: PredictionsSpeechToTextRequest) {
//        self.request = request
//    }
//
//    func fetchOnlineResult() async throws -> SpeechToTextResult {
//        guard let onlineService = predictionsService else {
//            let message = ConvertMultiServiceErrorMessage.onlineConvertServiceNotAvailable.errorDescription
//            let recoveryMessage = ConvertMultiServiceErrorMessage.onlineConvertServiceNotAvailable.recoverySuggestion
//            let predictionError = PredictionsError.service(message, recoveryMessage, nil)
//            throw predictionError
//        }
//
//        return try await onlineService.transcribe(
//            speechToText: request.speechToText,
//            language: request.options.language
//        )
//    }
//
//    func fetchOfflineResult() async throws -> SpeechToTextResult {
//        guard let offlineService = coreMLService else {
//            let message = ConvertMultiServiceErrorMessage.offlineConvertServiceNotAvailable.errorDescription
//            let recoveryMessage = ConvertMultiServiceErrorMessage.offlineConvertServiceNotAvailable.recoverySuggestion
//            let predictionError = PredictionsError.service(message, recoveryMessage, nil)
//            throw predictionError
//        }
//        return try await offlineService.transcribe(request.speechToText)
//    }
//
//    // MARK: -
//    func mergeResults(
//        offlineResult: ServiceResult?,
//        onlineResult: ServiceResult?
//    ) async throws -> SpeechToTextResult {
//
//        if offlineResult == nil && onlineResult == nil {
//            let message = ConvertMultiServiceErrorMessage.noResultConvertService.errorDescription
//            let recoveryMessage = ConvertMultiServiceErrorMessage.noResultConvertService.recoverySuggestion
//            let predictionError = PredictionsError.service(message, recoveryMessage, nil)
//            throw predictionError
//        }
//
//        guard let finalOfflineResult = offlineResult else {
//            // We are sure that the value will be non-nil at this point.
//            return onlineResult! // TODO: How sure are we about ^ ???
//        }
//
//        guard let finalOnlineResult = onlineResult else {
//            return finalOfflineResult
//        }
//
//        // At this point we decided not to merge the result and return the non-nil online
//        // result back.
//        return finalOnlineResult
//    }
//}
