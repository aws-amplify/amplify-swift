//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
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

    override func setUp() {
        let mockConfigurationJSON = """
        {
            "defaultRegion": "us_east_1"
        }
        """.data(using: .utf8)!
        do {
            let mockConfiguration = try JSONDecoder().decode(PredictionsPluginConfiguration.self,
                                                             from: mockConfigurationJSON)
            predictionsService = AWSPredictionsService(identifier: "",
                                                       awsTranslate: MockTranslateBehavior(),
                                                       awsRekognition: MockRekognitionBehavior(),
                                                       awsTextract: MockTextractBehavior(),
                                                       awsComprehend: mockComprehend,
                                                       awsPolly: MockPollyBehavior(),
                                                       config: mockConfiguration)
        } catch {
            XCTFail("Initialization of the text failed")
        }
    }

    func testWithOnlyLanguageResult() {
        let english = AWSComprehendDominantLanguage()!
        english.languageCode = "en"
        english.score = 0.5
        let mockDominantLanguage = mockDominantLanguageResult([english])
        mockComprehend.setResult(languageResponse: mockDominantLanguage)
        predictionsService.comprehend(text: inputForTest) { event in
            switch event {
            case .completed(let result):
                XCTAssertNotNil(result, "Result should be non-nil")
                XCTAssertEqual(result.language?.languageCode, .english, "Dominant language should match")
            case .failed(let error):
                XCTFail("Should not produce error: \(error)")
            }
        }
    }

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
        mockComprehend.setResult(languageResponse: mockDominantLanguage)
        predictionsService.comprehend(text: inputForTest) { event in
            switch event {
            case .completed(let result):
                XCTAssertNotNil(result, "Result should be non-nil")
                XCTAssertEqual(result.language?.languageCode, .italian, "Dominant language should match")
            case .failed(let error):
                XCTFail("Should not produce error: \(error)")
            }
        }
    }

    func testWithEmptyLanguageResult() {
        let mockDominantLanguage = mockDominantLanguageResult()
        mockComprehend.setResult(languageResponse: mockDominantLanguage)
        predictionsService.comprehend(text: inputForTest) { event in
            switch event {
            case .completed(let result):
                XCTFail("Should not produce result if the service cannot find the language. \(result)")
            case .failed(let error):
                XCTAssertNotNil(error, "Should return an error if language is nil. \(error)")
            }
        }
    }

    func testAllNilResult() {
        mockComprehend.setResult()
        predictionsService.comprehend(text: inputForTest) { event in
            switch event {
            case .completed(let result):
                XCTFail("Should not produce result if the service cannot find the language. \(result)")
            case .failed(let error):
                XCTAssertNotNil(error, "Should return an error if language is nil. \(error)")
            }
        }
    }

    func testLanguageError() {
        let mockError = NSError(domain: AWSComprehendErrorDomain,
                                code: AWSComprehendErrorType.internalServer.rawValue,
                                userInfo: [:])
        mockComprehend.setError(error: mockError)
        predictionsService.comprehend(text: inputForTest) { event in
            switch event {
            case .completed(let result):
                XCTFail("Should not produce result if the service cannot find the language. \(result)")
            case .failed(let error):
                XCTAssertNotNil(error, "Should return an error if server returned an error. \(error)")
            }
        }
    }

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
            case .failed(let error):
                XCTFail("Should not produce error: \(error)")
            }
        }
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
