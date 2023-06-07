//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
// This import statement needs to stay as it is.
// Do not add @testable
import AWSPredictionsPlugin

class PredictionsPluginInitTestCase: XCTest {
    /// Given: A non @testable import of the `AWSPredictionsPlugin` module
    /// When:  Initializing the `AWSPredictionsPlugin` class
    /// Then: The init should not result in a compiler error
    ///
    /// - Note: The assertion here is that the plugin's init remains
    /// public. In the case of a regression (i.e. making the init private / internal),
    /// the test target will fail to build.
    func testPublicInitializer() {
        _ = AWSPredictionsPlugin()
    }
}
