//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
import Amplify
import AWSPredictionsPlugin
import AWSCore

class InterpretBasicIntegrationTests: AWSPredictionsPluginTestBase {

    /// Test if we can make successful call to interpret
    ///
    /// - Given: Configured Amplify with prediction added
    /// - When:
    ///    - I invoke interpret with text
    /// - Then:
    ///    - Should return no empty result
    ///
    func testInterpretText() {
        let inputText = """
        Here is a text to be tested. This text contains emojis like 🙃😆 and like 🚀. Also it contains entities like
        places in Seattle and on November 19. Text is long enough to have happy emotions.
        """
        let interpretInvoked = expectation(description: "Interpret invoked")
        let operation = Amplify.Predictions.interpret(text: inputText) { event in
            switch event {
            case .success(let result):
                interpretInvoked.fulfill()
                XCTAssertNotNil(result, "Result should contain value")
            case .failure(let error):
                XCTFail("Should not receive error \(error)")
            }
        }
        XCTAssertNotNil(operation)
        waitForExpectations(timeout: networkTimeout)
    }

    /// Test if we can make successful calls to interpret when different input texts containing one or more
    /// emoji ZWJ (zero width joiner)/modifier sequences.
    ///
    /// - Given: Configured Amplify with prediction added
    /// - When:
    ///    - I invoke interpret with text
    /// - Then:
    ///    - Should return no empty result
    ///
    func testInterpretTextWithEmojisWithMultipleUnicodeScalars() {
        let inputTexts = [
            """
            👇🏾 is a modifier sequence combining 👇 Backhand Index Pointing Down and 🏾 Medium-Dark Skin
            tone.
            """,
            """
            “Here's to the crazy ones. The misfits. The rebels. The troublemakers 🏴‍☠️“.
            A pirate flag is ZWJ sequence combining  🏴, Zero Width Joiner and ☠️.
            """,
            """
            👩‍👩‍👧‍👧 family emojii is a ZWJ sequence combining:
                👩 Woman, Zero Width Joiner,
                👩 Woman, Zero Width Joiner,
                👧 Girl, Zero Width Joiner
                and a 👧 Girl.
            """
        ]

        for text in inputTexts {
            let interpretInvoked = expectation(description: "Interpret invoked")
            let operation = Amplify.Predictions.interpret(text: text) { event in
                switch event {
                case .success(let result):
                    interpretInvoked.fulfill()
                    XCTAssertNotNil(result, "Result should contain value")
                case .failure(let error):
                    XCTFail("Should not receive error \(error) for text \(text)")
                }
            }
            XCTAssertNotNil(operation)
            waitForExpectations(timeout: networkTimeout)
        }
    }

    /// Test if we can make successful call to interpret
    ///
    /// - Given: Configured Amplify with prediction added
    /// - When:
    ///    - I invoke interpret with text on offline mode
    /// - Then:
    ///    - Should return no empty result
    ///
    func testInterpretTextOffline() {
        let interpretInvoked = expectation(description: "Interpret invoked")
        let options = PredictionsInterpretRequest.Options(defaultNetworkPolicy: .offline, pluginOptions: nil)
        let operation = Amplify.Predictions.interpret(text: "Hello there how are you?", options: options) { event in
            switch event {
            case .success(let result):
                interpretInvoked.fulfill()
                XCTAssertNotNil(result, "Result should contain value")
            case .failure(let error):
                XCTFail("Should not receive error \(error)")
            }
        }
        XCTAssertNotNil(operation)
        waitForExpectations(timeout: networkTimeout)
    }
}
