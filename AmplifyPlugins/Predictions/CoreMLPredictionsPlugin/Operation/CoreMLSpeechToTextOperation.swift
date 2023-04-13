//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify

// TODO: Remove Operation

//public class CoreMLSpeechToTextOperation: AmplifyOperation<
//    PredictionsSpeechToTextRequest,
//    SpeechToTextResult,
//    PredictionsError
//>, PredictionsSpeechToTextOperation {
//
//       weak var coreMLSpeech: CoreMLSpeechBehavior?
//
//    init(_ request: PredictionsSpeechToTextRequest,
//         coreMLSpeech: CoreMLSpeechBehavior,
//         resultListener: ResultListener?) {
//
//        self.coreMLSpeech = coreMLSpeech
//        super.init(categoryType: .predictions,
//                   eventName: HubPayload.EventName.Predictions.speechToText,
//                   request: request,
//                   resultListener: resultListener)
//    }
//
//    override public func main() {
//        guard let coreMLSpeechAdapter = coreMLSpeech else {
//            finish()
//            return
//        }
//
//        if isCancelled {
//            finish()
//            return
//        }
//
//        coreMLSpeechAdapter.getTranscription(request.speechToText) { result in
//            guard let result = result else {
//                let errorDescription = CoreMLPluginErrorString.transcriptionNoResult.errorDescription
//                let recovery = CoreMLPluginErrorString.transcriptionNoResult.recoverySuggestion
//                let predictionsError = PredictionsError.service(errorDescription, recovery, nil)
//                self.dispatch(result: .failure(predictionsError))
//                self.finish()
//                return
//            }
//
//            self.dispatch(result: .success(result))
//            self.finish()
//        }
//
//    }
//}
