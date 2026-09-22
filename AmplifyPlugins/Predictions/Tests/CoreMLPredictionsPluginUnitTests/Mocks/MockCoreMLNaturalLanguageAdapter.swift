//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import XCTest
@testable import CoreMLPredictionsPlugin

// `@unchecked Sendable`: the protocol it conforms to now requires `Sendable`. Test double driven
// by a single test at a time.
final class MockCoreMLNaturalLanguageAdapter: CoreMLNaturalLanguageBehavior, @unchecked Sendable {

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
