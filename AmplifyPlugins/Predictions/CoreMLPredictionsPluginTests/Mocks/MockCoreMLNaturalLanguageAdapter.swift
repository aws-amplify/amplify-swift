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

    func detectDominantLanguage(for text: String) -> LanguageType? {
        return .italian
    }

    func getSyntaxTokens(for text: String) -> [SyntaxToken] {
        return []
    }

    func getEntities(for text: String) -> [EntityDetectionResult] {
        return []
    }

    func getSentiment(for text: String) -> Double {
        return 1.0
    }
}
