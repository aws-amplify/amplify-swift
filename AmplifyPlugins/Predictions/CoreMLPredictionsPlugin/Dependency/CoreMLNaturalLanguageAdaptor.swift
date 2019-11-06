//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify
import NaturalLanguage

struct CoreMLNaturalLanguageAdaptor: CoreMLNaturalLanguageBehavior {

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
        let options: NLTagger.Options = [.omitPunctuation, .omitWhitespace]
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

    func getEntities(for text: String) -> [EntityResult] {
        var result: [EntityResult] = []
        let tagger = NLTagger(tagSchemes: [.nameType])
        tagger.string = text
        let options: NLTagger.Options = [.omitPunctuation, .omitWhitespace, .joinNames]
        let tags: [NLTag] = [.personalName, .placeName, .organizationName]
        tagger.enumerateTags(in: text.startIndex ..< text.endIndex,
                             unit: .word,
                             scheme: .nameType,
                             options: options) { tag, tokenRange in

                                if let tag = tag, tags.contains(tag) {
                                    let entity = EntityResult(score: nil,
                                                              type: tag.getEntityType(),
                                                              targetText: String(text[tokenRange]),
                                                              range: tokenRange)
                                    result.append(entity)
                                }
                                return true
        }
        return result
    }

    func getSentinment(for text: String) -> Double {
        if #available(iOS 13, *) {
            let tagger = NLTagger(tagSchemes: [.sentimentScore])
            tagger.string = text

            let (sentiment, _) = tagger.tag(at: text.startIndex, unit: .paragraph, scheme: .sentimentScore)
            let score = Double(sentiment?.rawValue ?? "0") ?? 0
            return score
        }
        return 0.0
    }
}

extension NLTag {

    /// Convert the CoreML NLTag to SpeechType
    func getSpeechType() -> SpeechType {
        if self == .noun {
            return .noun
        }
        if self == .adjective {
            return .adjective
        }
        if self == .determiner {
            return .determiner
        }
        if self == .preposition {
            return .preposition
        }
        if self == .verb {
            return .verb
        }
        // TODO: Add the rest here
        return .other
    }

    func getEntityType() -> EntityType {
        if self == .placeName {
            return .location
        }
        // TODO: Add other entities
        return .other
    }
}

extension NLLanguage {

    func getLanguageType() -> LanguageType {
        if self == NLLanguage.english {
            return .english
        }
        if self == NLLanguage.italian {
            return .italian
        }
        return .undetermined
    }

}
