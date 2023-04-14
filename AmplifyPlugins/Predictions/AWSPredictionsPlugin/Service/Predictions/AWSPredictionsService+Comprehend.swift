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

    func comprehend(text: String) async throws -> Predictions.Interpret.Result {
        // We have to find the dominant language first and then invoke features.
        let (dominantLanguage, score) = try await fetchPredominantLanguage(text)
        var interpretResultBuilder = try await analyzeText(text, for: dominantLanguage)
        let languageDetected = LanguageDetectionResult(languageCode: dominantLanguage, score: score)
        interpretResultBuilder.with(language: languageDetected)
        return interpretResultBuilder.build()

    }

    private func fetchPredominantLanguage(
        _ text: String
    ) async throws -> (LanguageType, Double?) {
        let detectLanguage = DetectDominantLanguageInput(text: text)

        do {
            let response = try await awsComprehend.detectLanguage(request: detectLanguage)
            guard let dominantLanguage = response.languages?.getDominantLanguage(),
                  let dominantLanguageCode = dominantLanguage.languageCode
            else {
                let errorDescription = AWSComprehendErrorMessage.dominantLanguageNotDetermined.errorDescription
                let recoverySuggestion = AWSComprehendErrorMessage.dominantLanguageNotDetermined.recoverySuggestion
                let unknownError = PredictionsError.unknown(errorDescription, recoverySuggestion)
                throw unknownError
            }
            let locale = Locale(identifier: dominantLanguageCode)
            let languageType = LanguageType(locale: locale)
            return (languageType, dominantLanguage.score.map(Double.init))
        } catch {
            // TODO: Map to Amplify error type

            throw error
        }
    }

    /// Use the text and language code to fetch features
    /// - Parameter text: Input text
    /// - Parameter languageCode: Dominant language code
    private func analyzeText(_ text: String, for languageCode: LanguageType) async throws -> Predictions.Interpret.Result.Builder {
        let comprehendLanguageCode = languageCode.toComprehendLanguage()
        let syntaxLanguageCode = languageCode.toSyntaxLanguage()

        async let sentimentResult = try fetchSentimentResult(text, languageCode: comprehendLanguageCode)
        async let entitiesResult = try detectEntities(text, languageCode: comprehendLanguageCode)
        async let keyPhrasesResult = try fetchKeyPhrases(text, languageCode: comprehendLanguageCode)
        async let syntaxResult = try fetchSyntax(text, languageCode: syntaxLanguageCode)

        let (
            sentiment,
            entities,
            keyPhrases,
            syntax
        ) = try await (
            sentimentResult,
            entitiesResult,
            keyPhrasesResult,
            syntaxResult
        )

        var interpretResultBuilder = Predictions.Interpret.Result.Builder()
        interpretResultBuilder.with(sentiment: sentiment)
        interpretResultBuilder.with(entities: entities)
        interpretResultBuilder.with(keyPhrases: keyPhrases)
        interpretResultBuilder.with(syntax: syntax)
        return interpretResultBuilder
    }

    private func fetchSyntax(
        _ text: String,
        languageCode: ComprehendClientTypes.SyntaxLanguageCode
    ) async throws -> [SyntaxToken]? {

        let syntaxRequest = DetectSyntaxInput(languageCode: languageCode, text: text)
        let syntax = try await awsComprehend.detectSyntax(request: syntaxRequest)
        guard let syntaxTokens = syntax.syntaxTokens
        else {
            return nil
        }

        // TODO: Rewrite as ([A]) -> [B]
        var syntaxTokenResult = [SyntaxToken]() // ComprehendClientTypes.SyntaxToken]()
        for syntax in syntaxTokens {
            guard let comprehendPartOfSpeech = syntax.partOfSpeech,
                  let tag = comprehendPartOfSpeech.tag
            else { continue }

            let beginOffSet = syntax.beginOffset ?? 0
            let endOffset = syntax.endOffset ?? 0
            let startIndex = text.unicodeScalars.index(text.startIndex, offsetBy: beginOffSet)
            let endIndex = text.unicodeScalars.index(text.startIndex, offsetBy: endOffset)
            let range = startIndex ..< endIndex

            let score = comprehendPartOfSpeech.score
            let speechType = ComprehendClientTypes.PartOfSpeechTagType(rawValue: tag.rawValue)
            ?? .sdkUnknown(tag.rawValue)

            let partOfSpeech = PartOfSpeech(tag: speechType.getSpeechType(), score: score)

            let syntaxToken = SyntaxToken(
                tokenId: syntax.tokenId ?? 0,
                text: syntax.text ?? "",
                range: range,
                partOfSpeech: partOfSpeech
            )

            syntaxTokenResult.append(syntaxToken)
        }
        return syntaxTokenResult
    }

    private func fetchKeyPhrases(
        _ text: String,
        languageCode: ComprehendClientTypes.LanguageCode
    ) async throws -> [KeyPhrase]? {

        let keyPhrasesRequest = DetectKeyPhrasesInput(languageCode: languageCode, text: text)

        let keyPhrasesResponse = try await awsComprehend.detectKeyPhrases(request: keyPhrasesRequest)
        guard let keyPhrases = keyPhrasesResponse.keyPhrases
        else {
            return nil
        }

        var keyPhrasesResult = [KeyPhrase]()
        for keyPhrase in keyPhrases {

            let beginOffSet = keyPhrase.beginOffset ?? 0
            let endOffset = keyPhrase.endOffset ?? 0
            let startIndex = text.unicodeScalars.index(text.startIndex, offsetBy: beginOffSet)
            let endIndex = text.unicodeScalars.index(text.startIndex, offsetBy: endOffset)
            let range = startIndex ..< endIndex

            let amplifyKeyPhrase = KeyPhrase(
                text: keyPhrase.text ?? "",
                range: range,
                score: keyPhrase.score
            )

            keyPhrasesResult.append(amplifyKeyPhrase)
        }
        return keyPhrasesResult
    }

    private func fetchSentimentResult(
        _ text: String,
        languageCode: ComprehendClientTypes.LanguageCode
    ) async throws -> Sentiment? {
        let sentimentRequest = DetectSentimentInput(languageCode: languageCode, text: text)
        let sentimentResponse = try await awsComprehend.detectSentiment(request: sentimentRequest)

        guard let sentiment = sentimentResponse.sentiment?.toAmplifySentimentType(),
              let sentimentScore = sentimentResponse.sentimentScore
        else { return nil }

        let score: [SentimentType: Double] = [
            .positive: sentimentScore.positive.map(Double.init) ?? 0,
            .negative: sentimentScore.negative.map(Double.init) ?? 0,
            .mixed: sentimentScore.mixed.map(Double.init) ?? 0,
            .neutral: sentimentScore.neutral.map(Double.init) ?? 0
        ]

        return Sentiment(
            predominantSentiment: sentiment,
            sentimentScores: score
        )
    }

    private func detectEntities(
        _ text: String,
        languageCode: ComprehendClientTypes.LanguageCode
    ) async throws -> [EntityDetectionResult]? {
        let entitiesRequest = DetectEntitiesInput(languageCode: languageCode, text: text)
        let entitiesResponse = try await awsComprehend.detectEntities(request: entitiesRequest)
        guard let entities = entitiesResponse.entities
        else {
            return nil
        }

        // TODO: Convert to ([A]) -> [B]
        var entitiesResult = [EntityDetectionResult]()
        for entity in entities {
            let beginOffSet = entity.beginOffset ?? 0
            let endOffset = entity.endOffset ?? 0
            let startIndex = text.unicodeScalars.index(text.startIndex, offsetBy: beginOffSet)
            let endIndex = text.unicodeScalars.index(text.startIndex, offsetBy: endOffset)

            let range = startIndex ..< endIndex
            let interpretEntity = EntityDetectionResult(
                type: entity.type?.toAmplifyEntityType() ?? .unknown,
                targetText: entity.text ?? "",
                score: entity.score,
                range: range
            )
            entitiesResult.append(interpretEntity)
        }
        return entitiesResult
    }
}

extension Array where Element == ComprehendClientTypes.DominantLanguage {

    func getDominantLanguage() -> ComprehendClientTypes.DominantLanguage? {
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
            return item1Score < item2Score
        }
    }
}
