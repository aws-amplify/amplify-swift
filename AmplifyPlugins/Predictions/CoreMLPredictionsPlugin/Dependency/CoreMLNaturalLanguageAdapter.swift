//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify
import NaturalLanguage

class CoreMLNaturalLanguageAdapter: CoreMLNaturalLanguageBehavior {
    func detectDominantLanguage(for text: String) -> LanguageType? {
        let languageRecognizer = NLLanguageRecognizer()
        languageRecognizer.processString(text)
        return languageRecognizer.dominantLanguage?.getLanguageType()
    }

    func getSyntaxTokens(for text: String) -> [SyntaxToken] {
        var syntaxList: [SyntaxToken] = []
        var tokenId = 0
        let tagger = NLTagger(tagSchemes: [.lexicalClass])
        tagger.string = text
        let options: NLTagger.Options = [NLTagger.Options.omitPunctuation, .omitWhitespace]

        tagger.enumerateTags(
            in: text.startIndex ..< text.endIndex,
            unit: .word,
            scheme: .lexicalClass,
            options: options
        ) { tag, tokenRange in

            if let tag = tag {
                let partOfSpeech = PartOfSpeech(tag: tag.getSpeechType(), score: nil)
                let stringPart = String(text[tokenRange])
                let syntaxToken = SyntaxToken(
                    tokenId: tokenId,
                    text: stringPart,
                    range: tokenRange,
                    partOfSpeech: partOfSpeech
                )
                syntaxList.append(syntaxToken)
                tokenId += 1
            }
            return true
        }
        return syntaxList
    }

    func getEntities(for text: String) -> [EntityDetectionResult] {
        var result = [EntityDetectionResult]()
        let tagger = NLTagger(tagSchemes: [.nameType])
        tagger.string = text
        let options: NLTagger.Options = [NLTagger.Options.omitPunctuation, .omitWhitespace, .joinNames]
        let tags = [NLTag.personalName, .placeName, .organizationName]
        tagger.enumerateTags(
            in: text.startIndex ..< text.endIndex,
            unit: .word,
            scheme: .nameType,
            options: options
        ) { tag, tokenRange in
            if let tag = tag, tags.contains(tag) {
                let entity = EntityDetectionResult(
                    type: tag.getEntityType(),
                    targetText: String(text[tokenRange]),
                    score: nil,
                    range: tokenRange
                )
                result.append(entity)
            }
            return true
        }
        return result
    }

    func getSentiment(for text: String) -> Double {
        let tagger = NLTagger(tagSchemes: [.sentimentScore])
        tagger.string = text

        let (sentiment, _) = tagger.tag(at: text.startIndex, unit: .paragraph, scheme: .sentimentScore)
        let score = Double(sentiment?.rawValue ?? "0") ?? 0
        return score
    }
}

extension NLTag {

    // swiftlint:disable cyclomatic_complexity
    /// Convert the CoreML NLTag to SpeechType
    func getSpeechType() -> SpeechType {
        switch self {
        case .noun:
            return .noun
        case .adjective:
            return .adjective
        case .determiner:
            return .determiner
        case .preposition:
            return .preposition
        case .verb:
            return .verb
        case .adverb:
            return .adverb
        case .pronoun:
            return .pronoun
        case .particle:
            return .particle
        case .number:
            return .numeral
        case .conjunction:
            return .conjunction
        case .interjection:
            return .interjection
        case .openQuote, .closeQuote, .openParenthesis,
                .closeParenthesis, .dash, .otherPunctuation:
            return .symbol
        default:
            return .other

        }
    }
    // swiftlint:enable cyclomatic_complexity

    func getEntityType() -> EntityType {
        switch self {
        case .placeName:
            return .location
        case .personalName:
            return .person
        case .organizationName:
            return .organization
        default:
            return .other
        }
    }
}

extension NLLanguage {

    // swiftlint:disable:next function_body_length cyclomatic_complexity
    func getLanguageType() -> LanguageType {
        switch self {
        case .amharic:
            return .amharic
        case .arabic:
            return .arabic
        case .armenian:
            return .armenian
        case .bengali:
            return .bangla
        case .bulgarian:
            return .bulgarian
        case .burmese:
            return .burmese
        case .catalan:
            return .catalan
        case .cherokee:
            return .cherokee
        case .croatian:
            return .croatian
        case .czech:
            return .czech
        case .danish:
            return .danish
        case .dutch:
            return .dutch
        case .english:
            return .english
        case .finnish:
            return .finnish
        case .french:
            return .french
        case .georgian:
            return .georgian
        case .german:
            return .german
        case .greek:
            return .greek
        case .gujarati:
            return .gujarati
        case .hebrew:
            return .hebrew
        case .hindi:
            return .hindi
        case .hungarian:
            return .hungarian
        case .icelandic:
            return .icelandic
        case .indonesian:
            return .indonesian
        case .italian:
            return .italian
        case .japanese:
            return .japanese
        case .kannada:
            return .kannada
        case .khmer:
            return .khmer
        case .korean:
            return .korean
        case .lao:
            return .lao
        case .malay:
            return .malay
        case .malayalam:
            return .malayalam
        case .marathi:
            return .marathi
        case .mongolian:
            return .mongolian
        case .norwegian:
            return .norwegian
        case .oriya:
            return .odia
        case .persian:
            return .persian
        case .polish:
            return .polish
        case .portuguese:
            return .portuguese
        case .punjabi:
            return .punjabi
        case .romanian:
            return .romanian
        case .russian:
            return .russian
        case .simplifiedChinese:
            return .chinese
        case .sinhalese:
            return .sinhala
        case .slovak:
            return .slovak
        case .spanish:
            return .spanish
        case .swedish:
            return .swedish
        case .tamil:
            return .tamil
        case .telugu:
            return .telugu
        case .thai:
            return .thai
        case .tibetan:
            return .tibetan
        case .traditionalChinese:
            return .chinese
        case .turkish:
            return .turkish
        case .ukrainian:
            return .ukrainian
        case .urdu:
            return .urdu
        case .vietnamese:
            return .vietnamese
        default:
            return .undetermined
        }
    }

}
