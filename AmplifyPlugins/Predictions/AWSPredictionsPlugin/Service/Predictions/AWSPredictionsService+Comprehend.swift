//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
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
        let detectLanguage: AWSComprehendDetectDominantLanguageRequest = AWSComprehendDetectDominantLanguageRequest()
        detectLanguage.text = text
        
        awsComprehend.detectLanguage(request: detectLanguage).continueWith { [weak self] (task) -> Any? in
            guard task.error == nil else {
                onEvent(.failed(.networkError(task.error!.localizedDescription, task.error!.localizedDescription)))
                return nil
            }
            
            guard let result = task.result else {
                onEvent(.failed(.unknownError("No result was found. An unknown error occurred.", "Please try again.")))
                return nil
            }
            
            let dominantLanguageOptional = result.languages?.max { item1, item2 in
                guard let item1Score = item1.score else {
                    return false
                }
                guard let item2Score = item2.score else {
                    return true
                }
                return item1Score.doubleValue > item2Score.doubleValue
            }
            guard let dominantLanguageCode = dominantLanguageOptional?.languageCode else {
                //TODO: Return error from here
                return nil
            }
            
            if let interpretResult = self?.interpretTextFeatures(text, for: dominantLanguageCode) {
                onEvent(.completed(interpretResult))
            }
            return nil
        }
    }
    
    /// Use the text and language code to fetch features
    /// - Parameter text: Input text
    /// - Parameter languageCode: Dominant language code
    func interpretTextFeatures(_ text: String, for languageCode: String) -> InterpretResult {
        
        var sentimentResult: Sentiment?
        var entitiesResult: [EntityDetectionResult]?
        var keyPhrasesResult: [KeyPhrase]?
        var syntaxTokenResult: [SyntaxToken]?
        
        // Use dispatch group to group the parallel comprehend calls.
        let dispatchGroup = DispatchGroup()
        
        let comprehendLanguageCode = languageCodeToComprehendLanguage(languageCode)
        let syntaxLanguageCode = languageCodeToSyntaxLanguage(languageCode)
        dispatchGroup.enter()
        fetchSentimentResult(text, languageCode: comprehendLanguageCode) { (sentiment) in
            sentimentResult = sentiment
            dispatchGroup.leave()
        }
        
        dispatchGroup.enter()
        detectEntities(text, languageCode: comprehendLanguageCode) { (detectedEntities) in
            entitiesResult = detectedEntities
            dispatchGroup.leave()
        }
        
        dispatchGroup.enter()
        fetchKeyPhrases(text, languageCode: comprehendLanguageCode) { (keyPhrases) in
            keyPhrasesResult = keyPhrases
            dispatchGroup.leave()
        }
        dispatchGroup.enter()
        
        fetchSyntax(text, languageCode: syntaxLanguageCode) { (syntaxTokens) in
            syntaxTokenResult = syntaxTokens
            dispatchGroup.leave()
        }
        dispatchGroup.wait()
        var interpretResult = InterpretResult()
        interpretResult.entities = entitiesResult
        interpretResult.keyPhrases = keyPhrasesResult
        interpretResult.sentiment = sentimentResult
        interpretResult.syntax = syntaxTokenResult
        return interpretResult
    }
    
    func fetchSyntax(_ text: String,
                     languageCode: AWSComprehendSyntaxLanguageCode,
                     completionHandler: @escaping ([SyntaxToken]?) -> Void) {
        
        let syntaxRequest: AWSComprehendDetectSyntaxRequest = AWSComprehendDetectSyntaxRequest()
        syntaxRequest.languageCode  = languageCode
        syntaxRequest.text = text
        
        awsComprehend.detectSyntax(request: syntaxRequest).continueWith { (task) -> Any? in
            
            return nil
        }
    }
    
    func fetchKeyPhrases(_ text: String,
                         languageCode: AWSComprehendLanguageCode,
                         completionHandler: @escaping ([KeyPhrase]?) -> Void) {
        
        let keyPhrasesRequest: AWSComprehendDetectKeyPhrasesRequest = AWSComprehendDetectKeyPhrasesRequest()
        keyPhrasesRequest.languageCode = languageCode
        keyPhrasesRequest.text = text
        awsComprehend.detectKeyPhrases(request: keyPhrasesRequest).continueWith { (task) -> Any? in
            
            return nil
        }
        
    }
    
    func fetchSentimentResult(_ text: String,
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
                score = [SentimentType.positive: sentimentScore.positive?.doubleValue ?? 0.0]
            }
            completionHandler(Sentiment(predominantSentiment: predominantSentiment,
                                        sentimentScores: score))
            return nil
        }
        
    }
    
    func detectEntities(_ text: String,
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
                
                // TODO: Fix the range
                let range = Range<String.Index>(NSRange(location: entity.beginOffset?.intValue ?? 0,
                                                        length: entity.endOffset?.intValue ?? 0),
                                                in: text)!
                let interpretEntity = EntityDetectionResult(type: EntityType.event,
                                                            targetText: entity.text ?? "",
                                                            score: entity.score?.floatValue,
                                                            range: range)
                entitiesResult.append(interpretEntity)
            }
            completionHandler(entitiesResult)
            return nil
        }
        
    }
    
    /// Convert the language code to comprehend language code type
    /// - Parameter code: The language code in RFC 5646 code. For more information about
    /// RFC 5646, see <a href="https://tools.ietf.org/html/rfc5646"
    ///
    func languageCodeToComprehendLanguage(_ code: String) -> AWSComprehendLanguageCode {
        // TODO: Fill the right language codes below
        if code == "" {
            return .en
        }
        return .unknown
    }
    
    /// Convert the language code to comprehend syntax language code type
    /// - Parameter code: The language code in RFC 5646 code. For more information about
    /// RFC 5646, see <a href="https://tools.ietf.org/html/rfc5646"
    ///
    func languageCodeToSyntaxLanguage(_ code: String) -> AWSComprehendSyntaxLanguageCode {
        // TODO: Fill the right language codes below
        if code == "" {
            return .en
        }
        return .unknown
    }
}

extension AWSComprehendSentimentType {
    
    func toAmplifySentimentType() -> SentimentType {
        switch self {
        case .positive:
            return .positive
        case .neutral:
            return .neutral
        case .negative:
            return .negative
        case .mixed:
            return .mixed
        case .unknown:
            return .unknown
        @unknown default:
            return .unknown
        }
    }
}
