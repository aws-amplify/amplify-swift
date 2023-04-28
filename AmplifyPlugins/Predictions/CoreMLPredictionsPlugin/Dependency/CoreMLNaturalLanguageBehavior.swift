//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify

protocol CoreMLNaturalLanguageBehavior: AnyObject {

    /// Detect dominant language using coreml
    ///
    /// Will return nil if CoreML is not be able to infer the language
    ///
    /// - Parameter text: Input text
    func detectDominantLanguage(for text: String) -> Predictions.Language?

    /// Detect syntax tokens
    ///
    /// - Parameter text: Input text
    func getSyntaxTokens(for text: String) -> [Predictions.SyntaxToken]

    /// Get entities for the text
    ///
    /// - Parameter text: Input text
    func getEntities(for text: String) -> [Predictions.Entity.DetectionResult]

    /// Get the sentiment score of the given paragraph.
    ///
    /// The value maps the value given here `NLTagSchemeSentimentScore`
    ///
    /// - Parameter text: Input text
    func getSentiment(for text: String) -> Double
}
