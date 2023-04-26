//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

extension Predictions.Interpret {
    public struct Result {
        public let keyPhrases: [Predictions.KeyPhrase]?
        public let sentiment: Predictions.Sentiment?
        public let entities: [Predictions.Entity.DetectionResult]?
        public let language: Predictions.Language.DetectionResult?
        public let syntax: [Predictions.SyntaxToken]?
    }
}

extension Predictions.Interpret.Result {
    public struct Builder {
        var keyPhrases: [Predictions.KeyPhrase]?
        var sentiment: Predictions.Sentiment?
        var entities: [Predictions.Entity.DetectionResult]?
        var language: Predictions.Language.DetectionResult?
        var syntax: [Predictions.SyntaxToken]?

        public init() {}

        public func build() -> Predictions.Interpret.Result {
            let result = Predictions.Interpret.Result(
                keyPhrases: keyPhrases,
                sentiment: sentiment,
                entities: entities,
                language: language,
                syntax: syntax
            )
            return result
        }

        @discardableResult
        mutating public func with(keyPhrases: [Predictions.KeyPhrase]?) -> Builder {
            self.keyPhrases = keyPhrases
            return self
        }

        @discardableResult
        mutating public func with(sentiment: Predictions.Sentiment?) -> Builder {
            self.sentiment = sentiment
            return self
        }

        @discardableResult
        mutating public func with(entities: [Predictions.Entity.DetectionResult]?) -> Builder {
            self.entities = entities
            return self
        }

        @discardableResult
        mutating public func with(language: Predictions.Language.DetectionResult?) -> Builder {
            self.language = language
            return self
        }

        @discardableResult
        mutating public func with(syntax: [Predictions.SyntaxToken]?) -> Builder {
            self.syntax = syntax
            return self
        }
    }
}
