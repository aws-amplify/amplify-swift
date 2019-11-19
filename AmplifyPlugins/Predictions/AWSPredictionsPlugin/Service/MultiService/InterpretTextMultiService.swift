//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify

class InterpretTextMultiService: MultiServiceBehavior {

    typealias Event = PredictionsEvent<InterpretResult, PredictionsError>
    typealias InterpretTextEventHandler = (Event) -> Void

    var textToInterpret: String?
    weak var coreMLService: CoreMLPredictionBehavior?
    weak var predictionsService: AWSPredictionsService?

    init(coreMLService: CoreMLPredictionBehavior?,
         predictionsService: AWSPredictionsService?) {
        self.coreMLService = coreMLService
        self.predictionsService = predictionsService
    }

    func fetchOnlineResult(callback: @escaping InterpretTextEventHandler) {
        guard let onlineService = predictionsService else {
            let message = InterpretMultiServiceErrorMessage.onlineInterpretServiceNotAvailable.errorDescription
            let recoveryMessage = InterpretMultiServiceErrorMessage.onlineInterpretServiceNotAvailable.recoverySuggestion
            let predictionError = PredictionsError.service(message, recoveryMessage, nil)
            callback(.failed(predictionError))
            return
        }
        guard let text = textToInterpret else {
            let message = InterpretMultiServiceErrorMessage.textNotFoundToInterpret.errorDescription
            let recoveryMessage = InterpretMultiServiceErrorMessage.textNotFoundToInterpret.recoverySuggestion
            let predictionError = PredictionsError.service(message, recoveryMessage, nil)
            callback(.failed(predictionError))
            return
        }
        onlineService.comprehend(text: text, onEvent: callback)
    }

    func fetchOfflineResult(callback: @escaping InterpretTextEventHandler) {
        guard let offlineService = coreMLService else {
            let message = InterpretMultiServiceErrorMessage.offlineInterpretServiceNotAvailable.errorDescription
            let recoveryMessage = InterpretMultiServiceErrorMessage.offlineInterpretServiceNotAvailable.recoverySuggestion
            let predictionError = PredictionsError.service(message, recoveryMessage, nil)
            callback(.failed(predictionError))
            return
        }
        guard let text = textToInterpret else {
            let message = InterpretMultiServiceErrorMessage.textNotFoundToInterpret.errorDescription
            let recoveryMessage = InterpretMultiServiceErrorMessage.textNotFoundToInterpret.recoverySuggestion
            let predictionError = PredictionsError.service(message, recoveryMessage, nil)
            callback(.failed(predictionError))
            return
        }
        offlineService.comprehend(text: text, onEvent: callback)
    }

    func setTextToInterpret(text: String) {
        textToInterpret = text
    }

    // MARK: -

    func combineResults(offlineResult: InterpretResult?,
                        onlineResult: InterpretResult?,
                        callback: @escaping  InterpretTextEventHandler) {
        if offlineResult == nil && onlineResult == nil {
            let message = PredictionsServiceErrorMessage.interpretTextNoResult.errorDescription
            let recoveryMessage = PredictionsServiceErrorMessage.interpretTextNoResult.recoverySuggestion
            let predictionError = PredictionsError.service(message, recoveryMessage, nil)
            callback(.failed(predictionError))
        }

        guard let finalOfflineResult = offlineResult else {
            callback(.completed(onlineResult!))
            return
        }
        guard let finalOnlineResult = onlineResult else {
            callback(.completed(finalOfflineResult))
            return
        }

        // Combine Language detection
        var finalDetectedLanguage: LanguageDetectionResult?
        if let onlineDetectedLanguage = finalOnlineResult.language {
            finalDetectedLanguage = onlineDetectedLanguage
        } else {
            finalDetectedLanguage  = finalOfflineResult.language
        }

        // Combined final sentiment
        var finalSentiment: Sentiment?
        if let onlineSentiment = finalOnlineResult.sentiment,
            onlineSentiment.predominantSentiment != .unknown {

            finalSentiment = onlineSentiment
        } else {
            finalSentiment = offlineResult?.sentiment
        }

        // Combine KeyPhrase
        var finalKeyPhrases: [KeyPhrase]?
        if let onlineKeyPhrases = finalOnlineResult.keyPhrases,
            let offlineKeyPhrases = finalOfflineResult.keyPhrases {
            let onlineKeyPhraseSet = Set<KeyPhrase>(onlineKeyPhrases)
            let offlineKeyPhraseSet = Set<KeyPhrase>(offlineKeyPhrases)
            finalKeyPhrases = Array(onlineKeyPhraseSet.union(offlineKeyPhraseSet))
        } else {
            if let onlineKeyPrases = finalOnlineResult.keyPhrases {
                finalKeyPhrases = onlineKeyPrases
            } else {
                finalKeyPhrases = offlineResult?.keyPhrases
            }
        }

        // Combine Entity
        var finalEntities: [EntityDetectionResult]?
        if let onlineEntities = finalOnlineResult.entities,
            let offlineEntities = finalOfflineResult.entities {
            let onlineEntitiesSet = Set<EntityDetectionResult>(onlineEntities)
            let offlineEntitiesSet = Set<EntityDetectionResult>(offlineEntities)
            finalEntities = Array(onlineEntitiesSet.union(offlineEntitiesSet))
        } else {
            if let onlineEntities = finalOnlineResult.entities {
                finalEntities = onlineEntities
            } else {
                finalEntities = offlineResult?.entities
            }
        }
        // Combine syntax
        var finalSyntax: [SyntaxToken]?
        if let onlineSyntax = finalOnlineResult.syntax,
            let offlineSyntax = finalOfflineResult.syntax {
            let onlineSyntaxSet = Set<SyntaxToken>(onlineSyntax)
            let offlineSyntaxSet = Set<SyntaxToken>(offlineSyntax)
            finalSyntax = Array(onlineSyntaxSet.union(offlineSyntaxSet))
        } else {
            if let onlineSyntax = finalOnlineResult.syntax {
                finalSyntax = onlineSyntax
            } else {
                finalSyntax = offlineResult?.syntax
            }
        }
        var builder = InterpretResult.Builder()
        builder.with(language: finalDetectedLanguage)
        builder.with(sentiment: finalSentiment)
        builder.with(entities: finalEntities)
        builder.with(keyPhrases: finalKeyPhrases)
        builder.with(syntax: finalSyntax)
        callback(.completed(builder.build()))
    }
}

extension SyntaxToken: Hashable {

    public static func == (lhs: SyntaxToken, rhs: SyntaxToken) -> Bool {
        return lhs.text == rhs.text && lhs.range == rhs.range
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(text)
    }
}

extension KeyPhrase: Hashable {

    public static func == (lhs: KeyPhrase, rhs: KeyPhrase) -> Bool {
        return lhs.text == rhs.text && lhs.range == rhs.range
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(text)
        hasher.combine(range)
    }
}

extension EntityDetectionResult: Hashable {

    public static func == (lhs: EntityDetectionResult, rhs: EntityDetectionResult) -> Bool {
        return lhs.targetText == rhs.targetText &&
            lhs.range == rhs.range &&
            lhs.type == rhs.type
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(targetText)
        hasher.combine(range)
        hasher.combine(type)
    }
}
