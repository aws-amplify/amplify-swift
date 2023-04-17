//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify

class InterpretTextMultiService: MultiServiceBehavior {
    var textToInterpret: String?
    weak var coreMLService: CoreMLPredictionBehavior?
    weak var predictionsService: AWSPredictionsService?

    init(coreMLService: CoreMLPredictionBehavior?,
         predictionsService: AWSPredictionsService?) {
        self.coreMLService = coreMLService
        self.predictionsService = predictionsService
    }

    func fetchOnlineResult() async throws -> Predictions.Interpret.Result {
        guard let onlineService = predictionsService else {
            let message = InterpretMultiServiceErrorMessage.onlineInterpretServiceNotAvailable.errorDescription
            let recoveryMessage = InterpretMultiServiceErrorMessage
                .onlineInterpretServiceNotAvailable
                .recoverySuggestion
            let predictionError = PredictionsError.service(message, recoveryMessage, nil)
            throw predictionError
        }

        guard let text = textToInterpret else {
            let message = InterpretMultiServiceErrorMessage.textNotFoundToInterpret.errorDescription
            let recoveryMessage = InterpretMultiServiceErrorMessage.textNotFoundToInterpret.recoverySuggestion
            let predictionError = PredictionsError.service(message, recoveryMessage, nil)
            throw predictionError
        }

        return try await onlineService.comprehend(text: text)
    }

    func fetchOfflineResult() async throws -> Predictions.Interpret.Result {
        guard let offlineService = coreMLService else {
            let message = InterpretMultiServiceErrorMessage.offlineInterpretServiceNotAvailable.errorDescription
            let recoveryMessage = InterpretMultiServiceErrorMessage
                .offlineInterpretServiceNotAvailable
                .recoverySuggestion
            let predictionError = PredictionsError.service(message, recoveryMessage, nil)
            throw predictionError
        }
        guard let text = textToInterpret else {
            let message = InterpretMultiServiceErrorMessage.textNotFoundToInterpret.errorDescription
            let recoveryMessage = InterpretMultiServiceErrorMessage.textNotFoundToInterpret.recoverySuggestion
            let predictionError = PredictionsError.service(message, recoveryMessage, nil)
            throw predictionError
        }

        return try await offlineService.comprehend(text: text)
    }

    func setTextToInterpret(text: String) {
        textToInterpret = text
    }

    func mergeResults(
        offlineResult: Predictions.Interpret.Result?,
        onlineResult: Predictions.Interpret.Result?
    ) async throws -> Predictions.Interpret.Result {
        if offlineResult == nil && onlineResult == nil {
            let message = InterpretMultiServiceErrorMessage.interpretTextNoResult.errorDescription
            let recoveryMessage = InterpretMultiServiceErrorMessage.interpretTextNoResult.recoverySuggestion
            let predictionError = PredictionsError.service(message, recoveryMessage, nil)
            throw predictionError
        }

        guard let finalOfflineResult = offlineResult else {
            // We are sure that the value will be non-nil aat this point.
            return onlineResult!
        }

        guard let finalOnlineResult = onlineResult else {
            return finalOfflineResult
        }

        let finalDetectedLanguage = mergeLanguage(
            onlineResult: finalOnlineResult.language,
            offlineResult: finalOfflineResult.language
        )

        let finalSentiment = mergeSentiment(
            onlineResult: finalOnlineResult.sentiment,
            offlineResult: finalOfflineResult.sentiment
        )

        let finalEntities = mergeEntities(
            onlineResult: finalOnlineResult.entities,
            offlineResult: finalOfflineResult.entities
        )

        let finalKeyPhrases = mergeKeyPhrases(
            onlineResult: finalOnlineResult.keyPhrases,
            offlineResult: finalOfflineResult.keyPhrases
        )

        let finalSyntax = mergeSyntax(
            onlineResult: finalOnlineResult.syntax,
            offlineResult: finalOfflineResult.syntax
        )
        var builder = Predictions.Interpret.Result.Builder()
        builder.with(language: finalDetectedLanguage)
        builder.with(sentiment: finalSentiment)
        builder.with(entities: finalEntities)
        builder.with(keyPhrases: finalKeyPhrases)
        builder.with(syntax: finalSyntax)
        return builder.build()
    }

    func mergeLanguage(
        onlineResult: LanguageDetectionResult?,
        offlineResult: LanguageDetectionResult?
    ) -> LanguageDetectionResult? {
        return onlineResult ?? offlineResult
    }

    func mergeSentiment(
        onlineResult: Sentiment?,
        offlineResult: Sentiment?
    ) -> Sentiment? {
        guard let onlineSentiment = onlineResult,
            onlineSentiment.predominantSentiment != .unknown else {
                return offlineResult
        }
        return onlineSentiment
    }

    func mergeKeyPhrases(
        onlineResult: [KeyPhrase]?,
        offlineResult: [KeyPhrase]?
    ) -> [KeyPhrase]? {
        if let onlineKeyPhrases = onlineResult,
            let offlineKeyPhrases = offlineResult {
            let onlineKeyPhraseSet = Set<KeyPhrase>(onlineKeyPhrases)
            let offlineKeyPhraseSet = Set<KeyPhrase>(offlineKeyPhrases)
            return Array(onlineKeyPhraseSet.union(offlineKeyPhraseSet))
        }
        if let onlineKeyPrases = onlineResult {
            return onlineKeyPrases
        }
        return offlineResult
    }

    func mergeEntities(
        onlineResult: [EntityDetectionResult]?,
        offlineResult: [EntityDetectionResult]?
    ) -> [EntityDetectionResult]? {
        if let onlineEntities = onlineResult,
            let offlineEntities = offlineResult {
            let onlineEntitiesSet = Set<EntityDetectionResult>(onlineEntities)
            let offlineEntitiesSet = Set<EntityDetectionResult>(offlineEntities)
            return Array(onlineEntitiesSet.union(offlineEntitiesSet))
        }
        if let onlineEntities = onlineResult {
            return onlineEntities
        }
        return offlineResult
    }

    func mergeSyntax(
        onlineResult: [SyntaxToken]?,
        offlineResult: [SyntaxToken]?
    ) -> [SyntaxToken]? {
        if let onlineSyntax = onlineResult,
            let offlineSyntax = offlineResult {
            let onlineSyntaxSet = Set<SyntaxToken>(onlineSyntax)
            let offlineSyntaxSet = Set<SyntaxToken>(offlineSyntax)
            return Array(onlineSyntaxSet.union(offlineSyntaxSet))
        }
        if let onlineSyntax = onlineResult {
            return onlineSyntax
        }
        return offlineResult
    }
}

extension SyntaxToken: Hashable {
    public static func == (
        lhs: SyntaxToken,
        rhs: SyntaxToken
    ) -> Bool {
        lhs.text == rhs.text
        && lhs.range == rhs.range
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(text)
    }
}

extension KeyPhrase: Hashable {
    public static func == (
        lhs: KeyPhrase,
        rhs: KeyPhrase
    ) -> Bool {
        lhs.text == rhs.text
        && lhs.range == rhs.range
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(text)
        hasher.combine(range)
    }
}

extension EntityDetectionResult: Hashable {
    public static func == (
        lhs: EntityDetectionResult,
        rhs: EntityDetectionResult
    ) -> Bool {
        lhs.targetText == rhs.targetText
        && lhs.range == rhs.range
        && lhs.type == rhs.type
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(targetText)
        hasher.combine(range)
        hasher.combine(type)
    }
}
