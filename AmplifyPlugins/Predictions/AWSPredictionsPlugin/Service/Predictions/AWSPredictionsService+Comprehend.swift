//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import AWSComprehend
import Amplify

extension AWSPredictionsService: AWSComprehendServiceBehavior {

    func comprehend(text: String,
                    onEvent: @escaping AWSPredictionsService.ComprehendServiceEventHandler) {

        // We have to find the dominant language first and then invoke features.
        fetchPredominantLanguage(text) { event in

            switch event {
            case .completed(let dominantLanguageType, let score):
                self.analyzeText(text, for: dominantLanguageType) { analyzeResultBuilder in
                    var builder = analyzeResultBuilder
                    let languageDetected = LanguageDetectionResult(languageCode: dominantLanguageType, score: score)
                    builder.with(language: languageDetected)
                    onEvent(.completed(builder.build()))
                }
            case .failed(let error):
                onEvent(.failed(error))
            }
        }
    }

    private func fetchPredominantLanguage(_ text: String,
                                          completionHandler: @escaping (FetchDominantLanguageEvent) -> Void) {
        let detectLanguage: AWSComprehendDetectDominantLanguageRequest = AWSComprehendDetectDominantLanguageRequest()
        detectLanguage.text = text

        awsComprehend.detectLanguage(request: detectLanguage).continueWith { (task) -> Any? in
            if let languageError = task.error {
                let error = languageError as NSError
                let predictionsErrorString = PredictionsErrorHelper.mapPredictionsServiceError(error)
                completionHandler(.failed(.network(predictionsErrorString.errorDescription,
                                                   predictionsErrorString.recoverySuggestion)))
                return nil
            }

            guard let result = task.result else {
                let errorDescription = AWSComprehendErrorMessage.noLanguageFound.errorDescription
                let recoverySuggestion = AWSComprehendErrorMessage.noLanguageFound.recoverySuggestion
                let unknownError = PredictionsError.unknown(errorDescription, recoverySuggestion)
                completionHandler(.failed(unknownError))
                return nil
            }

            guard let  dominantLanguage = result.languages?.getDominantLanguage(),
                let dominantLanguageCode = dominantLanguage.languageCode else {
                    let errorDescription = AWSComprehendErrorMessage.dominantLanguageNotDetermined.errorDescription
                    let recoverySuggestion = AWSComprehendErrorMessage.dominantLanguageNotDetermined.recoverySuggestion
                    let unknownError = PredictionsError.unknown(errorDescription, recoverySuggestion)
                    completionHandler(.failed(unknownError))
                    return nil
            }
            let locale = Locale(identifier: dominantLanguageCode)
            let languageType = LanguageType(locale: locale)
            completionHandler(.completed(languageType, dominantLanguage.score?.doubleValue))
            return nil
        }
    }

    /// Use the text and language code to fetch features
    /// - Parameter text: Input text
    /// - Parameter languageCode: Dominant language code
    private func analyzeText(_ text: String, for languageCode: LanguageType,
                             completionHandler: @escaping (InterpretResult.Builder) -> Void) {
        DispatchQueue.global().async {
            var sentimentResult: Sentiment?
            var entitiesResult: [EntityDetectionResult]?
            var keyPhrasesResult: [KeyPhrase]?
            var syntaxTokenResult: [SyntaxToken]?

            // Use dispatch group to group the parallel comprehend calls.
            let dispatchGroup = DispatchGroup()

            let comprehendLanguageCode = languageCode.toComprehendLanguage()
            let syntaxLanguageCode = languageCode.toSyntaxLanguage()
            dispatchGroup.enter()
            self.fetchSentimentResult(text, languageCode: comprehendLanguageCode) { sentiment in
                sentimentResult = sentiment
                dispatchGroup.leave()
            }

            dispatchGroup.enter()
            self.detectEntities(text, languageCode: comprehendLanguageCode) { detectedEntities in
                entitiesResult = detectedEntities
                dispatchGroup.leave()
            }

            dispatchGroup.enter()
            self.fetchKeyPhrases(text, languageCode: comprehendLanguageCode) { keyPhrases in
                keyPhrasesResult = keyPhrases
                dispatchGroup.leave()
            }

            dispatchGroup.enter()
            self.fetchSyntax(text, languageCode: syntaxLanguageCode) { syntaxTokens in
                syntaxTokenResult = syntaxTokens
                dispatchGroup.leave()
            }
            dispatchGroup.wait()
            var interpretResultBuilder = InterpretResult.Builder()
            interpretResultBuilder.with(entities: entitiesResult)
            interpretResultBuilder.with(syntax: syntaxTokenResult)
            interpretResultBuilder.with(sentiment: sentimentResult)
            interpretResultBuilder.with(keyPhrases: keyPhrasesResult)
            completionHandler(interpretResultBuilder)
        }
    }

    private func fetchSyntax(_ text: String,
                             languageCode: AWSComprehendSyntaxLanguageCode,
                             completionHandler: @escaping ([SyntaxToken]?) -> Void) {

        let syntaxRequest: AWSComprehendDetectSyntaxRequest = AWSComprehendDetectSyntaxRequest()
        syntaxRequest.languageCode  = languageCode
        syntaxRequest.text = text

        awsComprehend.detectSyntax(request: syntaxRequest).continueWith { (task) -> Any? in
            guard let syntaxTokens = task.result?.syntaxTokens else {
                completionHandler(nil)
                return nil
            }
            var syntaxTokenResult = [SyntaxToken]()
            for syntax in syntaxTokens {
                guard let comprehendPartOfSpeech = syntax.partOfSpeech else {
                    continue
                }
                let beginOffSet = syntax.beginOffset?.intValue ?? 0
                let endOffset = syntax.endOffset?.intValue ?? 0
                let startIndex = text.unicodeScalars.index(text.startIndex, offsetBy: beginOffSet)
                let endIndex = text.unicodeScalars.index(text.startIndex, offsetBy: endOffset)
                let range = startIndex ..< endIndex

                let score = comprehendPartOfSpeech.score?.floatValue
                let speechType = comprehendPartOfSpeech.tag.getSpeechType()
                let partOfSpeech = PartOfSpeech(tag: speechType, score: score)
                let syntaxToken = SyntaxToken(tokenId: syntax.tokenId?.intValue ?? 0,
                                              text: syntax.text ?? "",
                                              range: range,
                                              partOfSpeech: partOfSpeech)
                syntaxTokenResult.append(syntaxToken)

            }
            completionHandler(syntaxTokenResult)
            return nil
        }
    }

    private func fetchKeyPhrases(_ text: String,
                                 languageCode: AWSComprehendLanguageCode,
                                 completionHandler: @escaping ([KeyPhrase]?) -> Void) {

        let keyPhrasesRequest: AWSComprehendDetectKeyPhrasesRequest = AWSComprehendDetectKeyPhrasesRequest()
        keyPhrasesRequest.languageCode = languageCode
        keyPhrasesRequest.text = text

        awsComprehend.detectKeyPhrases(request: keyPhrasesRequest).continueWith { (task) -> Any? in
            guard let keyPhrases = task.result?.keyPhrases else {
                completionHandler(nil)
                return nil
            }
            var keyPhrasesResult = [KeyPhrase]()
            for keyPhrase in keyPhrases {

                let beginOffSet = keyPhrase.beginOffset?.intValue ?? 0
                let endOffset = keyPhrase.endOffset?.intValue ?? 0
                let startIndex = text.unicodeScalars.index(text.startIndex, offsetBy: beginOffSet)
                let endIndex = text.unicodeScalars.index(text.startIndex, offsetBy: endOffset)
                let range = startIndex ..< endIndex
                let amplifyKeyPhrase = KeyPhrase(text: keyPhrase.text ?? "",
                                                 range: range,
                                                 score: keyPhrase.score?.floatValue)
                keyPhrasesResult.append(amplifyKeyPhrase)
            }
            completionHandler(keyPhrasesResult)
            return nil
        }
    }

    private func fetchSentimentResult(_ text: String,
                                      languageCode: AWSComprehendLanguageCode,
                                      completionHandler: @escaping (Sentiment?) -> Void) {

        let sentimentRequest: AWSComprehendDetectSentimentRequest = AWSComprehendDetectSentimentRequest()
        sentimentRequest.languageCode = languageCode
        sentimentRequest.text = text
        awsComprehend.detectSentiment(request: sentimentRequest).continueWith { (task) -> Any? in
            guard let result = task.result else {
                completionHandler(nil)
                return nil
            }
            let predominantSentiment = result.sentiment.toAmplifySentimentType()
            var score = [SentimentType: Double]()
            if let sentimentScore = result.sentimentScore {
                score = [SentimentType.positive: sentimentScore.positive?.doubleValue ?? 0.0,
                         .negative: sentimentScore.negative?.doubleValue ?? 0.0,
                         .mixed: sentimentScore.mixed?.doubleValue ?? 0.0,
                         .neutral: sentimentScore.neutral?.doubleValue ?? 0.0]
            }
            completionHandler(Sentiment(predominantSentiment: predominantSentiment,
                                        sentimentScores: score))
            return nil
        }
    }

    private func detectEntities(_ text: String,
                                languageCode: AWSComprehendLanguageCode,
                                completionHandler: @escaping ([EntityDetectionResult]?) -> Void) {

        let entitiesRequest: AWSComprehendDetectEntitiesRequest = AWSComprehendDetectEntitiesRequest()
        entitiesRequest.languageCode = languageCode
        entitiesRequest.text = text

        awsComprehend.detectEntities(request: entitiesRequest).continueWith { (task) -> Any? in
            guard let entities = task.result?.entities else {
                completionHandler(nil)
                return nil
            }
            var entitiesResult = [EntityDetectionResult]()
            for entity in entities {
                let beginOffSet = entity.beginOffset?.intValue ?? 0
                let endOffset = entity.endOffset?.intValue ?? 0
                let startIndex = text.unicodeScalars.index(text.startIndex, offsetBy: beginOffSet)
                let endIndex = text.unicodeScalars.index(text.startIndex, offsetBy: endOffset)
                let range = startIndex ..< endIndex
                let interpretEntity = EntityDetectionResult(type: entity.types.toAmplifyEntityType(),
                                                            targetText: entity.text ?? "",
                                                            score: entity.score?.floatValue,
                                                            range: range)
                entitiesResult.append(interpretEntity)
            }
            completionHandler(entitiesResult)
            return nil
        }
    }
}

extension Array where Element: AWSComprehendDominantLanguage {

    func getDominantLanguage() -> AWSComprehendDominantLanguage? {
        // SwiftFormat removes `self` below, but that leads to ambiguity between the instance method on Array and the
        // global `max` method. Adding `self` removes the ambiguity.
        // swiftformat:disable:next redundantSelf
        return self.max { item1, item2 in
            guard let item1Score = item1.score else {
                return false
            }
            guard let item2Score = item2.score else {
                return true
            }
            return item1Score.doubleValue < item2Score.doubleValue
        }
    }
}
