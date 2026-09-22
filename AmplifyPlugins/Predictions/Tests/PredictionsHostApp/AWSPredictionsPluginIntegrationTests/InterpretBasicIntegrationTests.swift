//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
@testable import Amplify
@testable import AWSPredictionsPlugin

// `@unchecked Sendable`: `XCTestCase` is not `Sendable`, but the test body is captured by the
// `@Sendable` closures the API now takes. XCTest runs one test at a time.
class InterpretBasicIntegrationTests: AWSPredictionsPluginTestBase, @unchecked Sendable {

    /// Test if we can make successful call to interpret
    ///
    /// - Given: Configured Amplify with prediction added
    /// - When:
    ///    - I invoke interpret with text
    /// - Then:
    ///    - Should return no empty result
    ///
    func testInterpretText() async throws {
        let inputText = """
        Here is a text to be tested. This text contains emojis like 🙃😆 and like 🚀. Also it contains entities like
        places in Seattle and on November 19. Text is long enough to have happy emotions.
        """
        let result = try await Amplify.Predictions.interpret(text: inputText, options: .init(defaultNetworkPolicy: .online))
        XCTAssertNotNil(result, "Result should contain value")
    }

    /// Test if we can make successful calls to interpret when different input texts containing one or more emoji ZWJ (zero width joiner)/modifier
    /// sequences.
    ///
    /// - Given: Configured Amplify with prediction added
    /// - When:
    ///    - I invoke interpret with text
    /// - Then:
    ///    - Should return no empty result
    ///
    func testInterpretTextWithEmojisWithMultipleUnicodeScalars() async throws {
        let inputTexts = [
            // 1
            """
            👇🏾 is a modifier sequence combining 👇 Backhand Index Pointing Down and 🏾 Medium-Dark Skin
            tone.
            """,
            // 2
            """
            “Here's to the crazy ones. The misfits. The rebels. The troublemakers 🏴‍☠️“.
            A pirate flag is ZWJ sequence combining  🏴, Zero Width Joiner and ☠️.
            """,
            // 3
            """
            👩‍👩‍👧‍👧 family emojii is a ZWJ sequence combining:
                👩 Woman, Zero Width Joiner,
                👩 Woman, Zero Width Joiner,
                👧 Girl, Zero Width Joiner
                and a 👧 Girl.
            """
        ]

        for text in inputTexts {
            let result = try await Amplify.Predictions.interpret(text: text, options: .init(defaultNetworkPolicy: .online))
            XCTAssertNotNil(result, "Result should contain value")
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
    func testInterpretTextOffline() async throws {
        let options = Predictions.Interpret.Options(
            defaultNetworkPolicy: .online,
            pluginOptions: nil
        )

        let result = try await Amplify.Predictions.interpret(
            text: "Hello there how are you?",
            options: options
        )

        XCTAssertNotNil(result, "Result should contain value")
    }
}
