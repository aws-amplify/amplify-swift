//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

#if canImport(Speech) && canImport(Vision) && !os(tvOS)
import Amplify
import XCTest
@testable import CoreMLPredictionsPlugin

class CoreMLPredictionsPluginTestBase: XCTestCase {
    var coreMLPredictionsPlugin: CoreMLPredictionsPlugin!
    var naturalLanguageBehavior: MockCoreMLNaturalLanguageAdapter!
    var visionBehavior: MockCoreMLVisionAdapter!
    var speechBehavior: MockCoreMLSpeechAdapter!
    var queue: MockOperationQueue!

    override func setUp() {
        coreMLPredictionsPlugin = CoreMLPredictionsPlugin()
        naturalLanguageBehavior = MockCoreMLNaturalLanguageAdapter()
        visionBehavior = MockCoreMLVisionAdapter()
        speechBehavior = MockCoreMLSpeechAdapter(
            response: .init(formattedString: "", isFinal: true)
        )
        queue = MockOperationQueue()
        coreMLPredictionsPlugin.configure(
            naturalLanguageBehavior: naturalLanguageBehavior,
            visionBehavior: visionBehavior,
            speechBehavior: speechBehavior,
            queue: queue
        )
    }
}
#endif
