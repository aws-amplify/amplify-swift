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
    var mockConfigurationJSON = """
    {
        "defaultRegion": "us-east-1"
    }
    """

    override func setUp() {


    }

    func setUpAmplify(withCollection: Bool = false) {

        if withCollection {
            //set test collection id to invoke collection method of rekognition
            mockConfigurationJSON = """
            {
                "defaultRegion": "us-east-1"
                "identify: : {
                    "identifyEntities" : {
                        "collectionId" : "TestCollection",
                        "maxFaces": 50,
                        "region": "us-west-2"
                    }
                }
            }
            """
        }

        do {
            let mockConfiguration = try JSONDecoder().decode(PredictionsPluginConfiguration.self,
                                                             from: mockConfigurationJSON.data(using: .utf8)!)
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
        setUpAmplify()
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
        setUpAmplify()
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

    /// Test whether we can make a successfull rekognition call to identify entities
    ///
    /// - Given: Predictions service with rekognition behavior
    /// - When:
    ///    - I invoke rekognition api in predictions service
    /// - Then:
    ///    - I should get back a result
    ///
    func testIdentifyEntitiesService() {
        setUpAmplify()
        let mockResponse: AWSRekognitionDetectFacesResponse = AWSRekognitionDetectFacesResponse()
        mockResponse.faceDetails = [AWSRekognitionFaceDetail]()

        mockRekognition.setFacesResponse(result: mockResponse)
        let testBundle = Bundle(for: type(of: self))
        guard let url = testBundle.url(forResource: "testImageEntities", withExtension: "jpg") else {
             XCTFail("Unable to find image")
             return
        }

        predictionsService.detectEntities(image: url) { event in
            switch event {
            case .completed(let result):
                let entitiesResult = result as? IdentifyEntitiesResult
                let newFaces = IdentifyEntitiesResultTransformers.processFaces(mockResponse.faceDetails!)
                XCTAssertEqual(entitiesResult?.entities.count, newFaces.count, "Faces count number should be the same")
            case .failed(let error):
                XCTFail("Should not produce error: \(error)")
            }
        }
    }

    func testIdentifyEntitiesServiceWithError() {
        setUpAmplify()
        let mockError = NSError(domain: AWSRekognitionErrorDomain,
                                code: AWSRekognitionErrorType.invalidImageFormat.rawValue,
                                userInfo: [:])
        mockRekognition.setError(error: mockError)
        let url = URL(fileURLWithPath: "")

        predictionsService.detectEntities(image: url) { event in
            switch event {
            case .completed(let result):
                XCTFail("Should not produce result: \(result)")
            case .failed(let error):
                XCTAssertNotNil(error, "Should produce an error")
            }
        }
    }

    /// Test whether we can make a successfull rekognition call to identify entities from a collection
    ///
    /// - Given: Predictions service with rekognition behavior
    /// - When:
    ///    - I invoke rekognition api in predictions service
    /// - Then:
    ///    - I should get back a result
    ///
    func testIdentifyEntityMatchesService() {
        setUpAmplify(withCollection: true)
        let mockResponse: AWSRekognitionSearchFacesByImageResponse = AWSRekognitionSearchFacesByImageResponse()
        mockResponse.faceMatches = [AWSRekognitionFaceMatch]()

        mockRekognition.setFacesFromCollection(result: mockResponse)
        let testBundle = Bundle(for: type(of: self))
        guard let url = testBundle.url(forResource: "testImageEntities", withExtension: "jpg") else {
             XCTFail("Unable to find image")
             return
        }

        predictionsService.detectEntities(image: url) { event in
            switch event {
            case .completed(let result):
                let entitiesResult = result as? IdentifyEntitiesResult
                let newFaces = IdentifyEntitiesResultTransformers.processCollectionFaces(mockResponse.faceMatches!)
                XCTAssertEqual(entitiesResult?.entities.count, newFaces.count, "Faces count number should be the same")
            case .failed(let error):
                XCTFail("Should not produce error: \(error)")
            }
        }
    }
}
