//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

/// <#Description#>
public struct InterpretResult {

    /// <#Description#>
    public let keyPhrases: [KeyPhrase]?

    /// <#Description#>
    public let sentiment: Sentiment?

    /// <#Description#>
    public let entities: [EntityDetectionResult]?

    /// <#Description#>
    public let language: LanguageDetectionResult?

    /// <#Description#>
    public let syntax: [SyntaxToken]?
}

extension InterpretResult {

    /// <#Description#>
    public struct Builder {

        var keyPhrases: [KeyPhrase]?
        var sentiment: Sentiment?
        var entities: [EntityDetectionResult]?
        var language: LanguageDetectionResult?
        var syntax: [SyntaxToken]?

        /// <#Description#>
        public init() {}

        /// <#Description#>
        /// - Returns: <#description#>
        public func build() -> InterpretResult {
            let result = InterpretResult(keyPhrases: keyPhrases,
                                         sentiment: sentiment,
                                         entities: entities,
                                         language: language,
                                         syntax: syntax)
            return result
        }

        /// <#Description#>
        /// - Parameter keyPhrases: <#keyPhrases description#>
        /// - Returns: <#description#>
        @discardableResult
        mutating public func with(keyPhrases: [KeyPhrase]?) -> Builder {
            self.keyPhrases = keyPhrases
            return self
        }

        /// <#Description#>
        /// - Parameter sentiment: <#sentiment description#>
        /// - Returns: <#description#>
        @discardableResult
        mutating public func with(sentiment: Sentiment?) -> Builder {
            self.sentiment = sentiment
            return self
        }

        /// <#Description#>
        /// - Parameter entities: <#entities description#>
        /// - Returns: <#description#>
        @discardableResult
        mutating public func with(entities: [EntityDetectionResult]?) -> Builder {
            self.entities = entities
            return self
        }

        /// <#Description#>
        /// - Parameter language: <#language description#>
        /// - Returns: <#description#>
        @discardableResult
        mutating public func with(language: LanguageDetectionResult?) -> Builder {
            self.language = language
            return self
        }

        /// <#Description#>
        /// - Parameter syntax: <#syntax description#>
        /// - Returns: <#description#>
        @discardableResult
        mutating public func with(syntax: [SyntaxToken]?) -> Builder {
            self.syntax = syntax
            return self
        }
    }
}
