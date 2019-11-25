//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
import AWSTranslate
import Amplify
@testable import AWSPredictionsPlugin

class PredictionsServiceTranslateTests: XCTestCase {

    var predictionsService: AWSPredictionsService!
    let mockTranslate = MockTranslateBehavior()

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
                                                       awsTranslate: mockTranslate,
                                                       awsRekognition: MockRekognitionBehavior(),
                                                       awsTextract: MockTextractBehavior(),
                                                       awsComprehend: MockComprehendBehavior(),
                                                       awsPolly: MockPollyBehavior(),
                                                       config: mockConfiguration)
        } catch {
            XCTFail("Initialization of the text failed")
        }
    }

    /// Test whether we can make a successfull translate call
    ///
    /// - Given: Predictions service with translate behavior
    /// - When:
    ///    - I invoke translate api in predictions service
    /// - Then:
    ///    - I should get back a result
    ///
    func testTranslateService() {
        let mockResponse = AWSTranslateTranslateTextResponse()!
        mockResponse.translatedText = "translated text here"
        mockTranslate.setResult(result: mockResponse)

        predictionsService.translateText(text: "Hello there",
                                         language: .english,
                                         targetLanguage: .italian) { event in
                                            switch event {
                                            case .completed(let result):
                                                XCTAssertEqual(result.text,
                                                               mockResponse.translatedText,
                                                               "Translated text should be same")
                                            case .failed(let error):
                                                XCTFail("Should not produce error: \(error)")
                                            }
        }
    }

    /// Test whether error is correctly propogated
    ///
    /// - Given: Predictions service with translate behavior
    /// - When:
    ///    - I invoke an invalid request
    /// - Then:
    ///    - I should get back a service error
    ///
    func testTranslateServiceWithError() {

        let mockError = NSError(domain: AWSTranslateErrorDomain,
                                code: AWSTranslateErrorType.invalidRequest.rawValue,
                                userInfo: [:])
        mockTranslate.setError(error: mockError)

        predictionsService.translateText(text: "",
                                         language: .english,
                                         targetLanguage: .italian) { event in
                                            switch event {
                                            case .completed(let result):
                                                XCTFail("Should not produce result: \(result)")
                                            case .failed(let error):
                                                XCTAssertNotNil(error, "Should produce an error")
                                            }
        }
    }
}
