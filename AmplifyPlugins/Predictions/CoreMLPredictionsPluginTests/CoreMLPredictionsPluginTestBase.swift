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

    var naturalLanguageBehavior: MockCoreMLNaturalLanguageAdaptor!

    var queue: MockOperationQueue!

    override func setUp() {
        coreMLPredictionsPlugin = CoreMLPredictionsPlugin()
        naturalLanguageBehavior = MockCoreMLNaturalLanguageAdaptor()
        queue = MockOperationQueue()
        coreMLPredictionsPlugin.configure(naturalLanguageBehavior: naturalLanguageBehavior,
                                          queue: queue)
    }
}
