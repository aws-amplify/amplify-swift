//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import CoreGraphics

/// Behavior of the Predictions category that clients will use
public protocol PredictionsCategoryClientBehavior {

    //TOOD: Update the api names after final review

    /// Translate the text to the language specified.
    /// - Parameter textToTranslate: The text to translate
    /// - Parameter language: The language of the text given
    /// - Parameter targetLanguage: The language to which the text should be translated
    /// - Parameter listener: Triggered when the event occurs
    /// - Parameter options: Parameters to specific plugin behavior
    func convert(textToTranslate: String,
                 language: LanguageType?,
                 targetLanguage: LanguageType?,
                 listener: PredictionsTranslateTextOperation.EventListener?,
                 options: PredictionsTranslateTextRequest.Options?) -> PredictionsTranslateTextOperation

    /// Translate the text to the language specified.
    /// - Parameter type: The type of image detection you want to perform
    /// - Parameter image: The image you are sending
    /// - Parameter options: Parameters to specific plugin behavior
    /// - Parameter listener: Triggered when the event occurs
    func identify(type: IdentifyType,
                  image: CGImage,
                  options: PredictionsIdentifyRequest.Options?,
                  listener: PredictionsIdentifyOperation.EventListener?) -> PredictionsIdentifyOperation

    /// Interpret the text and return  sentiment analysis, entity detection, language detection,
    /// syntax detection, key phrases detection
    /// - Parameter text: Text to interpret
    /// - Parameter options:Parameters to specific plugin behavior
    /// - Parameter options:Parameters to specific plugin behavior
    func interpret(text: String,
                   options: PredictionsInterpretRequest.Options?,
                   listener: PredictionsInterpretOperation.EventListener?) -> PredictionsInterpretOperation
}

// TODO: Move these enums to a separate file
/// Language type supported
public enum LanguageType: String {
    case english = "en"
    case italian = "it"
    case undetermined
}

public enum IdentifyType {
    case detectCelebrity
    case detectLabels
    case detectEntities
    case detectText
}

public struct InterpretTextResult {
    let keyPhrases: [KeyPhrase]
    let sentiment: Sentiment
    let entities: [EntityDetectionResult]
    let language: LanguageDetectionResult
    let syntax: [SyntaxToken]
}

// Sentiment Analysis
public struct Sentiment {
    let predominantSentiment: String
    let sentimentScores: [String: Float]?
}

// Entity Detection
public struct EntityDetectionResult {
    let type: EntityType
    let targetText: String
    let score: Float?
    let range: Range<String.Index>

    public init(type: EntityType,
                targetText: String,
                score: Float?,
                range: Range<String.Index>) {
        self.type = type
        self.targetText = targetText
        self.score = score
        self.range = range
    }
}


// Language Detection
public struct LanguageDetectionResult {
    let languageCode: LanguageType
    let score: Float?
}

// Syntax Detection
public struct SyntaxToken {
    let tokenId: Int
    let text: String
    let range: Range<String.Index>
    let partOfSpeech: PartOfSpeech

    public init(tokenId: Int,
                text: String,
                range: Range<String.Index>,
                partOfSpeech: PartOfSpeech) {
        self.tokenId = tokenId
        self.text = text
        self.range = range
        self.partOfSpeech = partOfSpeech
    }
}

public struct PartOfSpeech {
    let tag: SpeechType
    let score: Float?

    public init(tag: SpeechType, score: Float?) {
        self.tag = tag
        self.score = score
    }
}

// Key Phrase Detection
public struct KeyPhrase {
    let score: Float?
    let text: String
    let range: Range<String.Index>
}

public enum EntityType: String {
    case person = "PERSON"
    case location = "LOCATION"
    case organization = "ORGANIZATION"
    case commercialItem = "COMMERCIAL_ITEM"
    case event = "EVENT"
    case date = "DATE"
    case quantity = "QUANTITY"
    case title = "TITLE"
    case other = "OTHER"
}

public enum SpeechType: String {
    case adjective = "adj"
    case adposition = "adp"
    case adverb = "adv"
    case auxiliary = "aux"
    case conjunction = "conj"
    case coordinatingconjunction = "cconj"
    case determiner = "det"
    case interjection = "intj"
    case noun
    case numeral = "num"
    case other = "o"
    case particle = "part"
    case pronoun = "pron"
    case propernoun = "propn"
    case punctuation = "punct"
    case preposition
    case subordinatingconjunction = "sconj"
    case symbol = "sym"
    case verb
}
