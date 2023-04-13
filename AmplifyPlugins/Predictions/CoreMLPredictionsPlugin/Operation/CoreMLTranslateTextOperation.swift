////
//// Copyright Amazon.com Inc. or its affiliates.
//// All Rights Reserved.
////
//// SPDX-License-Identifier: Apache-2.0
////
//
//import Foundation
//import Amplify
//
//public class CoreMLTranslateTextOperation: AmplifyOperation<
//    PredictionsTranslateTextRequest,
//    TranslateTextResult,
//    PredictionsError
//>, PredictionsTranslateTextOperation {
//
//    init(_ request: PredictionsTranslateTextRequest,
//         resultListener: ResultListener?) {
//
//        super.init(categoryType: .predictions,
//                   eventName: HubPayload.EventName.Predictions.interpret,
//                   request: request,
//                   resultListener: resultListener)
//    }
//
//    override public func main() {
//        if isCancelled {
//            finish()
//            return
//        }
//
//        let errorDescription = CoreMLPluginErrorString.operationNotSupported.errorDescription
//        let recovery = CoreMLPluginErrorString.operationNotSupported.recoverySuggestion
//        let predictionsError = PredictionsError.service(errorDescription, recovery, nil)
//        dispatch(result: .failure(predictionsError))
//        finish()
//    }
//}
