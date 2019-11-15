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

extension InterpretResult {

    public struct Builder {

        var result: InterpretResult

        public init() {
            self.result = InterpretResult()
        }

        public func build() -> InterpretResult {
            return result
        }

        @discardableResult
        mutating public func with(keyPhrases: [KeyPhrase]?) -> Builder {
            result.keyPhrases = keyPhrases
            return self
        }

        @discardableResult
        mutating public func with(sentiment: Sentiment?) -> Builder {
            result.sentiment = sentiment
            return self
        }

        @discardableResult
        mutating public func with(entities: [EntityDetectionResult]?) -> Builder {
            result.entities = entities
            return self
        }

        @discardableResult
        mutating public func with(language: LanguageDetectionResult?) -> Builder {
            result.language = language
            return self
        }

        @discardableResult
        mutating public func with(syntax: [SyntaxToken]?) -> Builder {
            result.syntax = syntax
            return self
        }
    }
}
