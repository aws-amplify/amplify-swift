//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
import Amplify
@testable import CoreMLPredictionsPlugin

class CoreMLPredictionsPluginTestBase: XCTestCase {

    var coreMLPredictionsPlugin: CoreMLPredictionsPlugin!

    var naturalLanguageBehavior: MockCoreMLNaturalLanguageAdapter!

    var queue: MockOperationQueue!

    override func setUp() {
        coreMLPredictionsPlugin = CoreMLPredictionsPlugin()
        naturalLanguageBehavior = MockCoreMLNaturalLanguageAdapter()
        queue = MockOperationQueue()
        coreMLPredictionsPlugin.configure(naturalLanguageBehavior: naturalLanguageBehavior,
                                          queue: queue)
    }
}
