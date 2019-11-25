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
            case .failed(let error):
                XCTFail("Should not produce error: \(error)")
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

    private func mockEntitiesResult() -> AWSComprehendDetectEntitiesResponse {
        let mockResponse = AWSComprehendDetectEntitiesResponse()!
        return mockResponse
    }

    private func mockKeyPhrasesResult() -> AWSComprehendDetectKeyPhrasesResponse {
        let mockResponse = AWSComprehendDetectKeyPhrasesResponse()!
        return mockResponse
    }

    private func mockSyntaxResult() -> AWSComprehendDetectSyntaxResponse {
        let mockResponse = AWSComprehendDetectSyntaxResponse()!
        return mockResponse
    }
}
