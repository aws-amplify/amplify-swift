//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

public struct InterpretResult {

    var keyPhrases: [KeyPhrase]?
    var sentiment: Sentiment?
    var entities: [EntityDetectionResult]?
    var language: LanguageDetectionResult?
    var syntax: [SyntaxToken]?
}

public struct InterpretResultBuilder {

    var result: InterpretResult

    public init() {
        self.result = InterpretResult()
    }

    public func build() -> InterpretResult {
        return result
    }

    mutating public func addKeyPhrases(keyPhrases: [KeyPhrase]?) {
        result.keyPhrases = keyPhrases
    }

    mutating public func addSentiment(sentiment: Sentiment?) {
        result.sentiment = sentiment
    }

    mutating public func addEntities(entities: [EntityDetectionResult]?) {
        result.entities = entities
    }

    mutating public func addLanguage(language: LanguageDetectionResult?) {
        result.language = language
    }

    mutating public func addSyntax(syntax: [SyntaxToken]?) {
        result.syntax = syntax
    }
}
