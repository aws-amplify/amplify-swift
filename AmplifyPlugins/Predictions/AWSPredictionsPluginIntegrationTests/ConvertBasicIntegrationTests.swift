//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
import Amplify
import AWSPredictionsPlugin
import AWSCore

class ConvertBasicIntegrationTests: AWSPredictionsPluginTestBase {

    func testConvertSpeechToText() {
        let testBundle = Bundle(for: type(of: self))
        guard let url = testBundle.url(forResource: "audio", withExtension: "wav") else {
            return
        }

        let convertInvoked = expectation(description: "Convert operation invoked")
        let options = PredictionsConvertRequest.Options()
        let operation = Amplify.Predictions.convert(speechToText: url,
                                                    options: options) { event in
            switch event {
            case .completed(let result):
                DispatchQueue.main.async {
                convertInvoked.fulfill()
                XCTAssertNil(result, "Result should contain value")
                }
            case .failed(let error):
                XCTFail("Should not receieve error \(error)")
            default:
                break
            }

        }

        XCTAssertNotNil(operation)
        waitForExpectations(timeout: networkTimeout)
    }

    func testConvertSpeechToTextOffline() {
        let testBundle = Bundle(for: type(of: self))
        guard let url = testBundle.url(forResource: "audio", withExtension: "wav") else {
            return
        }

        let convertInvoked = expectation(description: "Convert operation invoked")
        let options = PredictionsConvertRequest.Options(defaultNetworkPolicy: .offline, voiceType: nil, pluginOptions: nil)
        let operation = Amplify.Predictions.convert(speechToText: url,
                                                    options: options) { event in
            switch event {
            case .completed(let result):
                convertInvoked.fulfill()
                XCTAssertNil(result, "Result should contain value")
            case .failed(let error):
                XCTFail("Should not receieve error \(error)")
            default:
                break
            }

        }

        XCTAssertNotNil(operation)
        waitForExpectations(timeout: networkTimeout)
    }

}
