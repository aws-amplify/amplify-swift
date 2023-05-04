//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
import Amplify
@testable import CoreMLPredictionsPlugin

class MockCoreMLNaturalLanguageAdapter: CoreMLNaturalLanguageBehavior {

    func detectDominantLanguage(for text: String) -> Predictions.Language? {
        return .italian
    }

    func getSyntaxTokens(for text: String) -> [Predictions.SyntaxToken] {
        return []
    }

    func getEntities(for text: String) -> [Predictions.Entity.DetectionResult] {
        return []
    }

    func getSentiment(for text: String) -> Double {
        return 1.0
    }
}
