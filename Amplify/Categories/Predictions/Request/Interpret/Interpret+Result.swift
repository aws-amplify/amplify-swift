//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

extension Predictions.Interpret {
    public struct Result {
        public let keyPhrases: [KeyPhrase]?
        public let sentiment: Sentiment?
        public let entities: [EntityDetectionResult]?
        public let language: LanguageDetectionResult?
        public let syntax: [SyntaxToken]?
    }
}
