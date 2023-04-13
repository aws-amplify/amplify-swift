//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify

//public class CoreMLInterpretTextOperation: AmplifyOperation<
//    PredictionsInterpretRequest,
//    InterpretResult,
//    PredictionsError
//>, PredictionsInterpretOperation {
//
//    weak var coreMLNaturalLanguage: CoreMLNaturalLanguageBehavior?
//
//    init(_ request: PredictionsInterpretRequest,
//         coreMLNaturalLanguage: CoreMLNaturalLanguageBehavior,
//         resultListener: ResultListener?) {
//
//        self.coreMLNaturalLanguage = coreMLNaturalLanguage
//        super.init(categoryType: .predictions,
//                   eventName: HubPayload.EventName.Predictions.interpret,
//                   request: request,
//                   resultListener: resultListener)
//    }
//
//    override public func cancel() {
//        super.cancel()
//    }
//
//    override public func main() {
//
//        guard let naturalLanguageAdapter = coreMLNaturalLanguage else {
//            finish()
//            return
//        }
//
//        var interpretResultBuilder = InterpretResult.Builder()
//        if let dominantLanguage = naturalLanguageAdapter.detectDominantLanguage(for: request.textToInterpret) {
//            let languageResult = LanguageDetectionResult(languageCode: dominantLanguage, score: nil)
//            interpretResultBuilder.with(language: languageResult)
//        }
//
//        if isCancelled {
//            finish()
//            return
//        }
//
//        let syntaxToken = naturalLanguageAdapter.getSyntaxTokens(for: request.textToInterpret)
//        interpretResultBuilder.with(syntax: syntaxToken)
//        if isCancelled {
//            finish()
//            return
//        }
//
//        let entities = naturalLanguageAdapter.getEntities(for: request.textToInterpret)
//        interpretResultBuilder.with(entities: entities)
//        if isCancelled {
//            finish()
//            return
//        }
//
//        let sentiment = naturalLanguageAdapter.getSentiment(for: request.textToInterpret)
//        var amplifySentiment: Sentiment!
//        switch sentiment {
//        case 0.0:
//            amplifySentiment = Sentiment(predominantSentiment: .neutral, sentimentScores: nil)
//        case -1.0 ..< 0.0:
//            amplifySentiment = Sentiment(predominantSentiment: .negative, sentimentScores: nil)
//        case 0.0 ... 1.0:
//            amplifySentiment = Sentiment(predominantSentiment: .positive, sentimentScores: nil)
//        default:
//            amplifySentiment = Sentiment(predominantSentiment: .mixed, sentimentScores: nil)
//        }
//        interpretResultBuilder.with(sentiment: amplifySentiment)
//        if isCancelled {
//            finish()
//            return
//        }
//
//        let interpretResult = interpretResultBuilder.build()
//        dispatch(result: .success(interpretResult))
//        finish()
//    }
//}
