//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
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
        tagger.enumerateTags(in: text.startIndex ..< text.endIndex,
                             unit: .word,
                             scheme: .lexicalClass,
                             options: options) { tag, tokenRange in

                                if let tag = tag {
                                    let partOfSpeech = PartOfSpeech(tag: tag.getSpeechType(), score: 1)
                                    let stringPart = String(text[tokenRange])
                                    let syntaxToken = SyntaxToken(tokenId: tokenId,
                                                                  text: stringPart,
                                                                  range: tokenRange,
                                                                  partOfSpeech: partOfSpeech)
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
        tagger.enumerateTags(in: text.startIndex ..< text.endIndex,
                             unit: .word,
                             scheme: .nameType,
                             options: options) { tag, tokenRange in

                                if let tag = tag, tags.contains(tag) {
                                    let entity = EntityDetectionResult(type: tag.getEntityType(),
                                                                       targetText: String(text[tokenRange]),
                                                                       score: nil,
                                                                       range: tokenRange)
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
        default:
            // TODO: Add the rest here
            return .other
        }
    }

    func getEntityType() -> EntityType {
        switch self {
        case .placeName:
            return .location
        default:
            // TODO: Add other entities
            return .other
        }
    }
}

extension NLLanguage {

    func getLanguageType() -> LanguageType {
        switch self {
        case .english:
            return .english
        case .italian:
            return .italian
        default:
            // TODO: Add other entities
            return .undetermined
        }
    }

}
