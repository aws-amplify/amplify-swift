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
//public class CoreMLIdentifyOperation: AmplifyOperation<
//    PredictionsIdentifyRequest,
//    IdentifyResult,
//    PredictionsError
//>, PredictionsIdentifyOperation {
//
//    weak var coreMLVision: CoreMLVisionBehavior?
//
//    init(_ request: PredictionsIdentifyRequest,
//         coreMLVision: CoreMLVisionBehavior,
//         resultListener: ResultListener?) {
//
//        self.coreMLVision = coreMLVision
//        super.init(categoryType: .predictions,
//                   eventName: HubPayload.EventName.Predictions.identifyLabels,
//                   request: request,
//                   resultListener: resultListener)
//    }
//
//    // swiftlint:disable cyclomatic_complexity
//    override public func main() {
//
//        guard let coreMLVisionAdapter = coreMLVision else {
//            finish()
//            return
//        }
//
//        if isCancelled {
//            finish()
//            return
//        }
//        switch request.identifyType {
//        case .detectCelebrity:
//            let errorDescription = CoreMLPluginErrorString.operationNotSupported.errorDescription
//            let recovery = CoreMLPluginErrorString.operationNotSupported.recoverySuggestion
//            let predictionsError = PredictionsError.service(errorDescription, recovery, nil)
//            dispatch(result: .failure(predictionsError))
//            finish()
//        case .detectText(let format):
//            switch format {
//            case .all, .table, .form:
//                let errorDescription = CoreMLPluginErrorString.operationNotSupported.errorDescription
//                let recovery = CoreMLPluginErrorString.operationNotSupported.recoverySuggestion
//                let predictionsError = PredictionsError.service(errorDescription, recovery, nil)
//                dispatch(result: .failure(predictionsError))
//                finish()
//            case .plain:
//                guard  let result = coreMLVisionAdapter.detectText(request.image) else {
//                    let errorDescription = CoreMLPluginErrorString.detectTextNoResult.errorDescription
//                    let recovery = CoreMLPluginErrorString.detectTextNoResult.recoverySuggestion
//                    let predictionsError = PredictionsError.service(errorDescription, recovery, nil)
//                    dispatch(result: .failure(predictionsError))
//                    finish()
//                    return
//                }
//                dispatch(result: .success(result))
//                finish()
//            }
//        case .detectEntities:
//            guard let result = coreMLVisionAdapter.detectEntities(request.image) else {
//                let errorDescription = CoreMLPluginErrorString.detectEntitiesNoResult.errorDescription
//                let recovery = CoreMLPluginErrorString.detectEntitiesNoResult.recoverySuggestion
//                let predictionsError = PredictionsError.service(errorDescription, recovery, nil)
//                dispatch(result: .failure(predictionsError))
//                finish()
//                return
//            }
//            dispatch(result: .success(result))
//            finish()
//        case .detectLabels(let labelType):
//            if labelType == .moderation { // coreml does not have an endpoint to detect moderation labels in images
//                let errorDescription = CoreMLPluginErrorString.operationNotSupported.errorDescription
//                let recovery = CoreMLPluginErrorString.operationNotSupported.recoverySuggestion
//                let predictionsError = PredictionsError.service(errorDescription, recovery, nil)
//                dispatch(result: .failure(predictionsError))
//                finish()
//                return
//            }
//            guard  let result = coreMLVisionAdapter.detectLabels(request.image) else {
//                let errorDescription = CoreMLPluginErrorString.detectLabelsNoResult.errorDescription
//                let recovery = CoreMLPluginErrorString.detectLabelsNoResult.recoverySuggestion
//                let predictionsError = PredictionsError.service(errorDescription, recovery, nil)
//                dispatch(result: .failure(predictionsError))
//                finish()
//                return
//            }
//            dispatch(result: .success(result))
//            finish()
//        }
//    }
//}
