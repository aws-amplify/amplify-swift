//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
import Amplify

class CoreMLPredictionsPluginIntegrationTest: AWSPredictionsPluginTestBase {

    func testIdentify() {
        let testBundle = Bundle(for: type(of: self))
        guard let url = testBundle.url(forResource: "people", withExtension: "jpg") else {
            return
        }
        let identifyInvoked = expectation(description: "Identify operation invoked")
        let operation = Amplify.Predictions.identify(type: .detectLabels(.all),
                                                     image: url) { event in
            switch event {
            case .success(let result):
                identifyInvoked.fulfill()
                XCTAssertNotNil(result, "Result should contain value")
            case .failure(let error):
                XCTFail("Should not receive error \(error)")
            }
        }
        XCTAssertNotNil(operation)
        waitForExpectations(timeout: networkTimeout)
    }
}
