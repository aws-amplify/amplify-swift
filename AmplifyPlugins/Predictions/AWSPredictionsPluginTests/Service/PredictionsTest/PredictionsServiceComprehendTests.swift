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
    let mockComprehend = MockComprehendBehavior()

    let inputForTest = "Input text for testing"

    override func setUp() async throws {
        let mockConfigurationJSON = """
        {
            "defaultRegion": "us_east_1"
        }
        """.data(using: .utf8)!

        do {
            let clientDelegate = NativeWSTranscribeStreamingClientDelegate()
            let dispatchQueue = DispatchQueue(label: "TranscribeStreamingTests")
            let nativeWebSocketProvider = NativeWebSocketProvider(clientDelegate: clientDelegate,
                                                                  callbackQueue: dispatchQueue)
            let mockConfiguration = try JSONDecoder().decode(PredictionsPluginConfiguration.self,
                                                             from: mockConfigurationJSON)
            predictionsService = AWSPredictionsService(identifier: "",
                                                       awsTranslate: MockTranslateBehavior(),
                                                       awsRekognition: MockRekognitionBehavior(),
                                                       awsTextract: MockTextractBehavior(),
                                                       awsComprehend: mockComprehend,
                                                       awsPolly: MockPollyBehavior(),
                                                       awsTranscribeStreaming: MockTranscribeBehavior(),
                                                       nativeWebSocketProvider: nativeWebSocketProvider,
                                                       transcribeClientDelegate: clientDelegate,
                                                       configuration: mockConfiguration)
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
    func testWithOnlyLanguageResult() {
        let english = AWSComprehendDominantLanguage()!
        english.languageCode = "en"
        english.score = 0.5
        let mockDominantLanguage = mockDominantLanguageResult([english])

        let resultReceived = expectation(description: "Transcription result should be returned")

        mockComprehend.setResult(languageResponse: mockDominantLanguage)
        predictionsService.comprehend(text: inputForTest) { event in
            switch event {
            case .completed(let result):
                XCTAssertNotNil(result, "Result should be non-nil")
                XCTAssertEqual(result.language?.languageCode, .english, "Dominant language should match")
                resultReceived.fulfill()
            case .failed(let error):
                XCTFail("Should not produce error: \(error)")
            }
        }

        waitForExpectations(timeout: 1)
    }

    /// Test whether we get correct dominant language for multiple languages
    ///
    /// - Given: Predictions service with comprehend behavior
    /// - When:
    ///    - I invoke comprehend text and service return multiple languages
    /// - Then:
    ///    - I should get back the language with highest score
    ///
    func testWithMultipleLanguageResult() {
        let english = AWSComprehendDominantLanguage()!
        english.languageCode = "en"
        english.score = 0.1
        let spanish = AWSComprehendDominantLanguage()!
        spanish.languageCode = "es"
        spanish.score = 0.2
        let italian = AWSComprehendDominantLanguage()!
        italian.languageCode = "it"
        italian.score = 0.6

        let mockDominantLanguage = mockDominantLanguageResult([english, spanish, italian])
        let resultReceived = expectation(description: "Transcription result should be returned")

        mockComprehend.setResult(languageResponse: mockDominantLanguage)
        predictionsService.comprehend(text: inputForTest) { event in
            switch event {
            case .completed(let result):
                XCTAssertNotNil(result, "Result should be non-nil")
                XCTAssertEqual(result.language?.languageCode, .italian, "Dominant language should match")
                resultReceived.fulfill()
            case .failed(let error):
                XCTFail("Should not produce error: \(error)")
            }
        }

        waitForExpectations(timeout: 1)
    }

    /// Test whether empty result from service gives us error
    ///
    /// - Given: Predictions service with comprehend behavior
    /// - When:
    ///    - I invoke comprehend text and service return empty result
    /// - Then:
    ///    - I should get an error
    ///
    func testWithEmptyLanguageResult() {
        let mockDominantLanguage = mockDominantLanguageResult()
        let errorReceived = expectation(description: "Error should be returned")

        mockComprehend.setResult(languageResponse: mockDominantLanguage)
        predictionsService.comprehend(text: inputForTest) { event in
            switch event {
            case .completed(let result):
                XCTFail("Should not produce result if the service cannot find the language. \(result)")
            case .failed(let error):
                XCTAssertNotNil(error, "Should return an error if language is nil. \(error)")
                errorReceived.fulfill()
            }
        }

        waitForExpectations(timeout: 1)
    }

    /// Test whether returninng all nil from service gives us an error
    ///
    /// - Given: Predictions service with comprehend behavior
    /// - When:
    ///    - I invoke comprehend with text
    /// - Then:
    ///    - I should get an error
    ///
    func testAllNilResult() {
        let errorReceived = expectation(description: "Error should be returned")

        mockComprehend.setResult()
        predictionsService.comprehend(text: inputForTest) { event in
            switch event {
            case .completed(let result):
                XCTFail("Should not produce result if the service cannot find the language. \(result)")
            case .failed(let error):
                XCTAssertNotNil(error, "Should return an error if language is nil. \(error)")
                errorReceived.fulfill()
            }
        }

        waitForExpectations(timeout: 1)
    }

    /// Test whether we get an error if service return error for language detection
    ///
    /// - Given: Predictions service with comprehend behavior
    /// - When:
    ///    - I invoke comprehend text and service returns an error
    /// - Then:
    ///    - I should get an error back
    ///
    func testLanguageError() {
        let mockError = NSError(domain: AWSComprehendErrorDomain,
                                code: AWSComprehendErrorType.internalServer.rawValue,
                                userInfo: [:])
        let errorReceived = expectation(description: "Error should be returned")

        mockComprehend.setError(error: mockError)
        predictionsService.comprehend(text: inputForTest) { event in
            switch event {
            case .completed(let result):
                XCTFail("Should not produce result if the service cannot find the language. \(result)")
            case .failed(let error):
                XCTAssertNotNil(error, "Should return an error if server returned an error. \(error)")
                errorReceived.fulfill()
            }
        }

        waitForExpectations(timeout: 1)
    }

    /// Test a complete response
    ///
    /// - Given: Predictions service with comprehend behavior
    /// - When:
    ///    - I invoke comprehend with all values
    /// - Then:
    ///    - I should get back the result
    ///
    func testCompleteResult() {

        let english = AWSComprehendDominantLanguage()!
        english.languageCode = "en"
        english.score = 0.2
        let spanish = AWSComprehendDominantLanguage()!
        spanish.languageCode = "es"
        spanish.score = 0.7
        let mockDominantLanguage = mockDominantLanguageResult([english, spanish])

        let adjToken = AWSComprehendSyntaxToken()!
        adjToken.beginOffset = 0
        adjToken.endOffset = 2
        let pos = AWSComprehendPartOfSpeechTag()!
        pos.score = 0.9
        pos.tag = .adj
        adjToken.partOfSpeech = pos
        let unknownToken = AWSComprehendSyntaxToken()!
        unknownToken.beginOffset = 0
        unknownToken.endOffset = 2
        let mockSyntaxTokens = mockSyntaxResult([adjToken, unknownToken])

        let mockSentiment = mockSentimentResult()

        let entity = AWSComprehendEntity()!
        entity.beginOffset = 0
        entity.endOffset = 3
        entity.text = "some text"
        entity.types = .commercialItem
        let mockEntities = mockEntitiesResult([entity])

        let keyPhrase = AWSComprehendKeyPhrase()!
        keyPhrase.beginOffset = 2
        keyPhrase.endOffset = 3
        keyPhrase.score = 0.8
        keyPhrase.text = "some text"

        let mockKeyPhrases = mockKeyPhrasesResult([keyPhrase])
        let resultReceived = expectation(description: "Transcription result should be returned")

        mockComprehend.setResult(sentimentResponse: mockSentiment,
                                 entitiesResponse: mockEntities,
                                 languageResponse: mockDominantLanguage,
                                 syntaxResponse: mockSyntaxTokens,
                                 keyPhrasesResponse: mockKeyPhrases)
        predictionsService.comprehend(text: inputForTest) { event in
            switch event {
            case .completed(let result):
                XCTAssertNotNil(result, "Result should be non-nil")
                XCTAssertEqual(result.language?.languageCode, .spanish, "Dominant language should match")
                resultReceived.fulfill()
            case .failed(let error):
                XCTFail("Should not produce error: \(error)")
            }
        }

        waitForExpectations(timeout: 1)
    }

    // MARK: - Helper methods

    private func mockDominantLanguageResult(_ languages: [AWSComprehendDominantLanguage]? = nil)
        -> AWSComprehendDetectDominantLanguageResponse {
            let mockResponse = AWSComprehendDetectDominantLanguageResponse()!
            mockResponse.languages = languages
            return mockResponse
    }

    private func mockSentimentResult() -> AWSComprehendDetectSentimentResponse {
        let mockResponse = AWSComprehendDetectSentimentResponse()!
        mockResponse.sentiment = .positive
        return mockResponse
    }

    private func mockEntitiesResult(_ entities: [AWSComprehendEntity]? = nil) -> AWSComprehendDetectEntitiesResponse {
        let mockResponse = AWSComprehendDetectEntitiesResponse()!
        mockResponse.entities = entities
        return mockResponse
    }

    private func mockKeyPhrasesResult(_ keyPhrases: [AWSComprehendKeyPhrase]? = nil)
        -> AWSComprehendDetectKeyPhrasesResponse {

            let mockResponse = AWSComprehendDetectKeyPhrasesResponse()!
            mockResponse.keyPhrases = keyPhrases
            return mockResponse
    }

    private func mockSyntaxResult(_ syntaxTokens: [AWSComprehendSyntaxToken]? = nil)
        -> AWSComprehendDetectSyntaxResponse {

            let mockResponse = AWSComprehendDetectSyntaxResponse()!
            mockResponse.syntaxTokens = syntaxTokens
            return mockResponse
    }
}
