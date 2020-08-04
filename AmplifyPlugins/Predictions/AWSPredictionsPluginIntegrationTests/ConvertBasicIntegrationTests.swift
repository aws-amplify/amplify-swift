//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
import Amplify
import AWSPredictionsPlugin
import AWSCore

class ConvertBasicIntegrationTests: AWSPredictionsPluginTestBase {

    // this test only tests online functionality.
    // offline functionality cannot be tested through an
    // integration test because speech recognition through
    // CoreML has to be run on device only.
    func testConvertSpeechToText() {
        let testBundle = Bundle(for: type(of: self))
        guard let url = testBundle.url(forResource: "audio", withExtension: "wav") else {
            return
        }

        let convertInvoked = expectation(description: "Convert operation invoked")
        let options = PredictionsSpeechToTextRequest.Options(defaultNetworkPolicy: .auto,
                                                             language: .usEnglish,
                                                             pluginOptions: nil)
        let operation = Amplify.Predictions.convert(speechToText: url,
                                                    options: options) { event in
            switch event {
            case .success(let result):
                convertInvoked.fulfill()
                XCTAssertNotNil(result, "Result should contain value")
            case .failure(let error):
                DispatchQueue.main.async {
                    XCTFail("Should not receieve error \(error)")
                }
            }

        }

        XCTAssertNotNil(operation)
        waitForExpectations(timeout: networkTimeout)
    }
}
