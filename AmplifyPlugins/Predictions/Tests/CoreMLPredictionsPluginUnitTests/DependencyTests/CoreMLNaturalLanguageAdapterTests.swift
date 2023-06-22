//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
@testable import Amplify
@testable import CoreMLPredictionsPlugin

class CoreMLNaturalLanguageAdapterTests: XCTestCase {

    var coreMLNaturalLanguageAdapter: CoreMLNaturalLanguageAdapter!

    override func setUp() {
        coreMLNaturalLanguageAdapter = CoreMLNaturalLanguageAdapter()
    }

    /// Test to see if we get dominant language for valid text
    ///
    /// - Given: CoreML Adapter
    /// - When:
    ///    - Invoke detect dominant language with a valid text
    /// - Then:
    ///    - Get the correct dominant language
    ///
    func testDominantLanguage() {
        let result = coreMLNaturalLanguageAdapter.detectDominantLanguage(for: "Hello there how are you")
        XCTAssertNotNil(result, "Result should not be nil")
        XCTAssertEqual(result, .english, "Detected language should be English")
    }

    /// Test to see if we get nil for scrambled text
    ///
    /// - Given: CoreML Adapter
    /// - When:
    ///    - Invoke detect dominant language with a scrambled text
    /// - Then:
    ///    - Get nil
    ///
    func testDominantLanguageWithInvalidText() {
        let result = coreMLNaturalLanguageAdapter.detectDominantLanguage(for: "(%*%#@")
        XCTAssertNil(result, "Result should be nil")
    }

    /// Test if syntax token is working
    ///
    /// - Given: CoreML Adapter
    /// - When:
    ///    - I invoke get syntax token with valid text
    /// - Then:
    ///    - I should get back correct tokens
    ///
    func testSyntaxToken() {
        #if !os(xrOS)
        // TODO: Test failing on visionOS.
        // XCTAssertEqual failed: ("PartOfSpeech(description: "other")")
        // is not equal to ("PartOfSpeech(description: "determiner")") -
        // First word in the input should be determiner
        let text = "The ripe taste of cheese improves with age."
        let result = coreMLNaturalLanguageAdapter.getSyntaxTokens(for: text)
        XCTAssertNotNil(result, "Result should not be nil")
        XCTAssertFalse(result.isEmpty, "Should return some value back")
        let detectedPartOfSpeech = result[0].detectedPartOfSpeech
        XCTAssertEqual(
            detectedPartOfSpeech.partOfSpeech,
            .determiner,
            "First word in the input should be determiner"
        )
        #endif
    }

    /// Test syntax token with invalid text
    ///
    /// - Given: CoreML Adapter
    /// - When:
    ///    - I invoke get syntax token with invalid text
    /// - Then:
    ///    - I should get back empty result
    ///
    func testSyntaxTokenWithInvalidText() {
        let text = "(%*%#@"
        let result = coreMLNaturalLanguageAdapter.getSyntaxTokens(for: text)
        XCTAssertNotNil(result, "Result should not be nil")
        XCTAssertTrue(result.isEmpty, "Should return some value back")
    }

    /// Test entities with valid text
    ///
    /// - Given: CoreML Adapter
    /// - When:
    ///    - I invoke get enitites token with valid text
    /// - Then:
    ///    - I should get back valid result
    ///
    func testEntityToken() {
        #if !os(xrOS) // TODO: Test failing on visionOS.
        let text = "The American Red Cross was established in Washington, D.C., by Clara Barton."
        let result = coreMLNaturalLanguageAdapter.getEntities(for: text)
        XCTAssertNotNil(result, "Result should not be nil")
        XCTAssertFalse(result.isEmpty, "Should return some value back")
        #endif
    }

    /// Test entities with valid text
    ///
    /// - Given: CoreML Adapter
    /// - When:
    ///    - I invoke get enitites token with valid text
    /// - Then:
    ///    - I should get back valid result
    ///
    func testEntityTokenWithInvalidText() {
        let text = "#($*(#&%*$^*"
        let result = coreMLNaturalLanguageAdapter.getEntities(for: text)
        XCTAssertNotNil(result, "Result should not be nil")
        XCTAssertTrue(result.isEmpty, "Should return empty result")
    }

    /// Test if sentiment score works
    ///
    /// - Given: CoreML Adapter
    /// - When:
    ///    - I invoke get sentiment
    /// - Then:
    ///    - I should get back a valid sentiment score
    ///
    func testSentiment() {
        let text = "I am feeling very happy"
        let score = coreMLNaturalLanguageAdapter.getSentiment(for: text)
        XCTAssertTrue(score <= 1.0, "Sentiment score should be in range [1.0,-1.0]. \(score)")
        XCTAssertTrue(score >= -1.0, "Sentiment score should be in range [1.0,-1.0]. \(score)")
    }
}
