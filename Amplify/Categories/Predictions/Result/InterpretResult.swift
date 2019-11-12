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

    @discardableResult
    mutating public func with(keyPhrases: [KeyPhrase]?) -> InterpretResultBuilder {
        result.keyPhrases = keyPhrases
        return self
    }

    @discardableResult
    mutating public func with(sentiment: Sentiment?) -> InterpretResultBuilder {
        result.sentiment = sentiment
        return self
    }

    @discardableResult
    mutating public func with(entities: [EntityDetectionResult]?) -> InterpretResultBuilder {
        result.entities = entities
        return self
    }

    @discardableResult
    mutating public func with(language: LanguageDetectionResult?) -> InterpretResultBuilder {
        result.language = language
        return self
    }

    @discardableResult
    mutating public func with(syntax: [SyntaxToken]?) -> InterpretResultBuilder {
        result.syntax = syntax
        return self
    }
}
