//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
import AWSRekognition
import AWSTextract
import CoreML
import Amplify
@testable import AWSPredictionsPlugin

class PredictionsServiceRekognitionTests: XCTestCase {

    var predictionsService: AWSPredictionsService!
    let mockRekognition = MockRekognitionBehavior()

    override func setUp() {
        let mockConfigurationJSON = """
        {
            "defaultRegion": "us-east-1"
        }
        """.data(using: .utf8)!
        do {
            let mockConfiguration = try JSONDecoder().decode(PredictionsPluginConfiguration.self,
                                                             from: mockConfigurationJSON)
            predictionsService = AWSPredictionsService(identifier: "",
                                                       awsTranslate: MockTranslateBehavior(),
                                                       awsRekognition: mockRekognition,
                                                       awsTextract: MockTextractBehavior(),
                                                       awsComprehend: MockComprehendBehavior(),
                                                       awsPolly: MockPollyBehavior(),
                                                       config: mockConfiguration)
        } catch {
            XCTFail("Initialization of the text failed")
        }
    }

    /// Test whether we can make a successfull rekognition call to identify labels
    ///
    /// - Given: Predictions service with rekognition behavior
    /// - When:
    ///    - I invoke rekognition api in predictions service
    /// - Then:
    ///    - I should get back a result
    ///
    func testIdentifyLabelsService() {
        let mockResponse: AWSRekognitionDetectLabelsResponse = AWSRekognitionDetectLabelsResponse()
        mockResponse.labels = [AWSRekognitionLabel]()

        mockRekognition.setLabelsResponse(result: mockResponse)
        let testBundle = Bundle(for: type(of: self))
        guard let url = testBundle.url(forResource: "testImageLabels", withExtension: "jpg") else {
             XCTFail("Unable to find image")
             return
        }

        predictionsService.detectLabels(image: url, type: .labels) { event in
            switch event {
            case .completed(let result):
                let labelResult = result as? IdentifyLabelsResult
                let labels = IdentifyLabelsResultTransformers.processLabels(mockResponse.labels!)
                XCTAssertEqual(labelResult?.labels, labels, "Labels should be the same")
            case .failed(let error):
                XCTFail("Should not produce error: \(error)")
            }
        }
    }

    /// Test whether error is correctly propogated
    ///
    /// - Given: Predictions service with rekogniton behavior
    /// - When:
    ///    - I invoke an invalid request
    /// - Then:
    ///    - I should get back a service error
    ///
    func testIdentifyLabelsServiceWithError() {
        let mockError = NSError(domain: AWSRekognitionErrorDomain,
                                code: AWSRekognitionErrorType.invalidImageFormat.rawValue,
                                userInfo: [:])
        mockRekognition.setError(error: mockError)
        let url = URL(fileURLWithPath: "")

        predictionsService.detectLabels(image: url, type: .labels) { event in
            switch event {
            case .completed(let result):
                XCTFail("Should not produce result: \(result)")
            case .failed(let error):
                XCTAssertNotNil(error, "Should produce an error")
            }
        }
    }
}
