//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify

class InterpretTextMultiService: MultiServiceBehavior {
    weak var coreMLService: CoreMLPredictionBehavior?
    weak var predictionsService: AWSPredictionsService?
    let textToInterpret: String

    init(
        coreMLService: CoreMLPredictionBehavior?,
        predictionsService: AWSPredictionsService?,
        textToInterpret: String
    ) {
        self.coreMLService = coreMLService
        self.predictionsService = predictionsService
        self.textToInterpret = textToInterpret
    }

    func fetchOnlineResult() async throws -> Predictions.Interpret.Result {
        guard let onlineService = predictionsService else {
            throw PredictionsError.client(.onlineInterpretServiceUnavailable)
        }

        return try await onlineService.comprehend(text: textToInterpret)
    }

    func fetchOfflineResult() async throws -> Predictions.Interpret.Result {
        guard let offlineService = coreMLService else {
            throw PredictionsError.client(.offlineInterpretServiceUnavailable)
        }
        return try await offlineService.comprehend(text: textToInterpret)
    }

    func mergeResults(
        offlineResult: Predictions.Interpret.Result?,
        onlineResult: Predictions.Interpret.Result?
    ) async throws -> Predictions.Interpret.Result {
        switch (offlineResult, onlineResult) {
        case (.some(let offline), .some(let online)):
            let finalDetectedLanguage = mergeLanguage(
                onlineResult: online.language,
                offlineResult: offline.language
            )

            let finalSentiment = mergeSentiment(
                onlineResult: online.sentiment,
                offlineResult: offline.sentiment
            )

            let finalEntities = mergeEntities(
                onlineResult: online.entities,
                offlineResult: offline.entities
            )

            let finalKeyPhrases = mergeKeyPhrases(
                onlineResult: online.keyPhrases,
                offlineResult: offline.keyPhrases
            )

            let finalSyntax = mergeSyntax(
                onlineResult: online.syntax,
                offlineResult: offline.syntax
            )

            let result = Predictions.Interpret.Result(
                keyPhrases: finalKeyPhrases,
                sentiment: finalSentiment,
                entities: finalEntities,
                language: finalDetectedLanguage,
                syntax: finalSyntax
            )
            return result
        case (.some(let offline), .none):
            return offline
        case (.none, .some(let online)):
            return online
        case (.none, .none):
            throw PredictionsError.client(.unableToInterpretText)
        }
    }

    func mergeLanguage(
        onlineResult: Predictions.Language.DetectionResult?,
        offlineResult: Predictions.Language.DetectionResult?
    ) -> Predictions.Language.DetectionResult? {
        return onlineResult ?? offlineResult
    }

    func mergeSentiment(
        onlineResult: Predictions.Sentiment?,
        offlineResult: Predictions.Sentiment?
    ) -> Predictions.Sentiment? {
        guard let onlineSentiment = onlineResult,
            onlineSentiment.predominantSentiment != .unknown else {
                return offlineResult
        }
        return onlineSentiment
    }

    func mergeKeyPhrases(
        onlineResult: [Predictions.KeyPhrase]?,
        offlineResult: [Predictions.KeyPhrase]?
    ) -> [Predictions.KeyPhrase]? {
        if let onlineKeyPhrases = onlineResult,
            let offlineKeyPhrases = offlineResult {
            let onlineKeyPhraseSet = Set<Predictions.KeyPhrase>(onlineKeyPhrases)
            let offlineKeyPhraseSet = Set<Predictions.KeyPhrase>(offlineKeyPhrases)
            return Array(onlineKeyPhraseSet.union(offlineKeyPhraseSet))
        }
        if let onlineKeyPrases = onlineResult {
            return onlineKeyPrases
        }
        return offlineResult
    }

    func mergeEntities(
        onlineResult: [Predictions.Entity.DetectionResult]?,
        offlineResult: [Predictions.Entity.DetectionResult]?
    ) -> [Predictions.Entity.DetectionResult]? {
        if let onlineEntities = onlineResult,
            let offlineEntities = offlineResult {
            let onlineEntitiesSet = Set<Predictions.Entity.DetectionResult>(onlineEntities)
            let offlineEntitiesSet = Set<Predictions.Entity.DetectionResult>(offlineEntities)
            return Array(onlineEntitiesSet.union(offlineEntitiesSet))
        }
        if let onlineEntities = onlineResult {
            return onlineEntities
        }
        return offlineResult
    }

    func mergeSyntax(
        onlineResult: [Predictions.SyntaxToken]?,
        offlineResult: [Predictions.SyntaxToken]?
    ) -> [Predictions.SyntaxToken]? {
        if let onlineSyntax = onlineResult,
            let offlineSyntax = offlineResult {
            let onlineSyntaxSet = Set<Predictions.SyntaxToken>(onlineSyntax)
            let offlineSyntaxSet = Set<Predictions.SyntaxToken>(offlineSyntax)
            return Array(onlineSyntaxSet.union(offlineSyntaxSet))
        }
        if let onlineSyntax = onlineResult {
            return onlineSyntax
        }
        return offlineResult
    }
}

extension Predictions.SyntaxToken: Hashable {
    public static func == (
        lhs: Self,
        rhs: Self
    ) -> Bool {
        lhs.text == rhs.text
        && lhs.range == rhs.range
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(text)
    }
}

extension Predictions.KeyPhrase: Hashable {
    public static func == (
        lhs: Self,
        rhs: Self
    ) -> Bool {
        lhs.text == rhs.text
        && lhs.range == rhs.range
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(text)
        hasher.combine(range)
    }
}

extension Predictions.Entity.DetectionResult: Hashable {
    public static func == (
        lhs: Self,
        rhs: Self
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
