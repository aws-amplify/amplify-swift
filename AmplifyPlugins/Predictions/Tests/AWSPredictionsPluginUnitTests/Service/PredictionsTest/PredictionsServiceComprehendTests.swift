//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
import AWSComprehend
import Amplify
@testable import AWSPredictionsPlugin

class PredictionsServiceComprehendTests: XCTestCase {
    var predictionsService: AWSPredictionsService!
    var mockComprehend: MockComprehendBehavior!
    let inputForTest = "Input text for testing"

    override func setUp() {
        let mockConfigurationJSON = """
        {
            "defaultRegion": "us_east_1"
        }
        """
        
        do {
            let mockConfiguration = try JSONDecoder().decode(
                PredictionsPluginConfiguration.self,
                from: Data(mockConfigurationJSON.utf8)
            )
            mockComprehend = MockComprehendBehavior()
            predictionsService = AWSPredictionsService(
                identifier: "",
                awsTranslate: MockTranslateBehavior(),
                awsRekognition: MockRekognitionBehavior(),
                awsTextract: MockTextractBehavior(),
                awsComprehend: mockComprehend,
                awsPolly: MockPollyBehavior(),
                awsTranscribeStreaming: MockTranscribeBehavior(),
                configuration: mockConfiguration
            )
        } catch {
            XCTFail("Initialization of the text failed")
        }
    }

    /// Test comprehend text with only dominant language result
    ///
    /// - Given: Predictions service with comprehend behavior
    /// - When:
    ///    - I invoke comprehend text
    /// - Then:
    ///    - I should get back a result with dominant language
    ///
    func testWithOnlyLanguageResult() async throws {
        let mockDominantLanguage = DetectDominantLanguageOutputResponse(
            languages: [.init(languageCode: "en", score: 0.5)]
        )
        mockComprehend.languageResponse = { _ in mockDominantLanguage }
        mockComprehend.sentimentResponse = { _ in .init() }
        mockComprehend.keyPhrasesResponse = { _ in .init() }
        mockComprehend.syntaxResponse = { _ in .init() }
        mockComprehend.entitiesResponse = { _ in .init() }

        let result = try await predictionsService.comprehend(text: inputForTest)
        XCTAssertNotNil(result, "Result should be non-nil")
        XCTAssertEqual(result.language?.languageCode, .english, "Dominant language should match")
    }

    /// Test whether we get correct dominant language for multiple languages
    ///
    /// - Given: Predictions service with comprehend behavior
    /// - When:
    ///    - I invoke comprehend text and service return multiple languages
    /// - Then:
    ///    - I should get back the language with highest score
    ///
    func testWithMultipleLanguageResult() async throws {
        let english = ComprehendClientTypes.DominantLanguage(languageCode: "en", score: 0.1)
        let spanish = ComprehendClientTypes.DominantLanguage(languageCode: "es", score: 0.2)
        let italian = ComprehendClientTypes.DominantLanguage(languageCode: "it", score: 0.6)
        let mockDominantLanguage = DetectDominantLanguageOutputResponse(
            languages: [english, spanish, italian]
        )
        mockComprehend.languageResponse = { _ in mockDominantLanguage }
        mockComprehend.sentimentResponse = { _ in .init() }
        mockComprehend.keyPhrasesResponse = { _ in .init() }
        mockComprehend.syntaxResponse = { _ in .init() }
        mockComprehend.entitiesResponse = { _ in .init() }

        let result = try await predictionsService.comprehend(text: inputForTest)
        XCTAssertNotNil(result, "Result should be non-nil")
        XCTAssertEqual(result.language?.languageCode, .italian, "Dominant language should match")
    }

    /// Test whether empty result from service gives us error
    ///
    /// - Given: Predictions service with comprehend behavior
    /// - When:
    ///    - I invoke comprehend text and service return empty result
    /// - Then:
    ///    - I should get an error
    ///
    func testWithEmptyLanguageResult() async throws {
        let mockDominantLanguage = DetectDominantLanguageOutputResponse()
        mockComprehend.languageResponse = { _ in mockDominantLanguage }

        do {
            let result = try await predictionsService.comprehend(text: inputForTest)
            XCTFail("Should not produce result if the service cannot find the language. \(result)")
        } catch {
            XCTAssertNotNil(error, "Should return an error if language is nil. \(error)")
        }
    }

    /// Test whether we get an error if service return error for language detection
    ///
    /// - Given: Predictions service with comprehend behavior
    /// - When:
    ///    - I invoke comprehend text and service returns an error
    /// - Then:
    ///    - I should get an error back
    ///
    func testLanguageError() async throws {
        let mockError = NSError(
            domain: "aws.rekognition.errordomain",
            code: 42,
            userInfo: [:]
        )

        mockComprehend.languageResponse = { _ in throw mockError }
        mockComprehend.sentimentResponse = { _ in .init() }
        mockComprehend.keyPhrasesResponse = { _ in .init() }
        mockComprehend.syntaxResponse = { _ in .init() }
        mockComprehend.entitiesResponse = { _ in .init() }

        do {
            let result = try await predictionsService.comprehend(text: inputForTest)
            XCTFail("Should not produce result if the service cannot find the language. \(result)")
        } catch {
            XCTAssertNotNil(error, "Should return an error if server returned an error. \(error)")
        }
    }

    /// Test a complete response
    ///
    /// - Given: Predictions service with comprehend behavior
    /// - When:
    ///    - I invoke comprehend with all values
    /// - Then:
    ///    - I should get back the result
    ///
    func testCompleteResult() async throws {
        let english = ComprehendClientTypes.DominantLanguage(languageCode: "en", score: 0.2)
        let spanish = ComprehendClientTypes.DominantLanguage(languageCode: "es", score: 0.7)
        let mockDominantLanguage = DetectDominantLanguageOutputResponse(
            languages: [english, spanish]
        )
        mockComprehend.languageResponse = { _ in mockDominantLanguage }

        let partOfSpeech = ComprehendClientTypes.PartOfSpeechTag(score: 0.9, tag: .adj)
        let adjToken = ComprehendClientTypes.SyntaxToken(
            beginOffset: 0,
            endOffset: 2,
            partOfSpeech: partOfSpeech
        )
        let unknownToken = ComprehendClientTypes.SyntaxToken(beginOffset: 0, endOffset: 2)
        let mockSyntaxTokens = DetectSyntaxOutputResponse(syntaxTokens: [adjToken, unknownToken])
        mockComprehend.syntaxResponse = { _ in mockSyntaxTokens }

        let mockSentiment = DetectSentimentOutputResponse(sentiment: .positive)
        mockComprehend.sentimentResponse = { _ in mockSentiment }

        let entity = ComprehendClientTypes.Entity(
            beginOffset: 0,
            endOffset: 3,
            text: "some text",
            type: .commercialItem
        )
        let mockEntities = DetectEntitiesOutputResponse(entities: [entity])
        mockComprehend.entitiesResponse = { _ in mockEntities }

        let keyPhrase = ComprehendClientTypes.KeyPhrase(
            beginOffset: 2,
            endOffset: 3,
            score: 0.8,
            text: "some text"
        )
        let mockKeyPhrases = DetectKeyPhrasesOutputResponse(keyPhrases: [keyPhrase])
        mockComprehend.keyPhrasesResponse = { _ in mockKeyPhrases }

        let result = try await predictionsService.comprehend(text: inputForTest)
        XCTAssertNotNil(result, "Result should be non-nil")
        XCTAssertEqual(result.language?.languageCode, .spanish, "Dominant language should match")
    }
}
