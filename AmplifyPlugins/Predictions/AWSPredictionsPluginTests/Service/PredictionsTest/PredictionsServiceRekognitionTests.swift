//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
import AWSRekognition
import CoreML
import Amplify
import Foundation
@testable import AWSPredictionsPlugin

// swiftlint:disable file_length type_body_length
class PredictionsServiceRekognitionTests: XCTestCase {

    var predictionsService: AWSPredictionsService!
    let mockRekognition = MockRekognitionBehavior()
    var mockConfigurationJSON = """
    {
        "defaultRegion": "us-west-2"
    }
    """

    override func setUp() async throws {

    }

    func setUpAmplify(withCollection: Bool = false) {

        if withCollection {
            // set test collection id to invoke collection method of rekognition
            mockConfigurationJSON = """
            {
            "defaultRegion": "us-west-2",
            "identify": {
            "identifyEntities": {
            "collectionId": "TestCollection",
            "maxFaces": 50,
            "region": "us-west-2"
            }
            }
            }
            """
        }

        do {
            let clientDelegate = NativeWSTranscribeStreamingClientDelegate()
            let dispatchQueue = DispatchQueue(label: "TranscribeStreamingTests")
            let nativeWebSocketProvider = NativeWebSocketProvider(clientDelegate: clientDelegate,
                                                                  callbackQueue: dispatchQueue)
            let mockConfiguration = try JSONDecoder().decode(PredictionsPluginConfiguration.self,
                                                             from: mockConfigurationJSON.data(using: .utf8)!)
            predictionsService = AWSPredictionsService(identifier: "",
                                                       awsTranslate: MockTranslateBehavior(),
                                                       awsRekognition: mockRekognition,
                                                       awsTextract: MockTextractBehavior(),
                                                       awsComprehend: MockComprehendBehavior(),
                                                       awsPolly: MockPollyBehavior(),
                                                       awsTranscribeStreaming: MockTranscribeBehavior(),
                                                       nativeWebSocketProvider: nativeWebSocketProvider,
                                                       transcribeClientDelegate: clientDelegate,
                                                       configuration: mockConfiguration)
        } catch {
            print(error)
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

        let resultReceived = expectation(description: "Transcription result should be returned")
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
                resultReceived.fulfill()
            case .failed(let error):
                XCTFail("Should not produce error: \(error)")
            }
        }

        waitForExpectations(timeout: 1)
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

        let errorReceived = expectation(description: "Error should be returned")
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
                errorReceived.fulfill()
            }
        }

        waitForExpectations(timeout: 1)
    }

    /// Test whether error is correctly propogated
    ///
    /// - Given: Predictions service with rekogniton behavior
    /// - When:
    ///    - I invoke an invalid request
    /// - Then:
    ///    - I should get back a service error because response was nil
    ///
    func testIdentifyLabelsServiceWithNilResponse() {
        setUpAmplify()
        mockRekognition.setLabelsResponse(result: nil)

        let errorReceived = expectation(description: "Error should be returned")
        let testBundle = Bundle(for: type(of: self))
        guard let url = testBundle.url(forResource: "testImageLabels", withExtension: "jpg") else {
            XCTFail("Unable to find image")
            return
        }

        predictionsService.detectLabels(image: url, type: .labels) { event in
            switch event {
            case .completed(let result):
                XCTFail("Should not produce result: \(result)")
            case .failed(let error):
                XCTAssertNotNil(error, "Should produce an error")
                errorReceived.fulfill()
            }
        }

        waitForExpectations(timeout: 1)
    }

    /// Test whether we can make a successful rekognition call to identify moderation labels
    ///
    /// - Given: Predictions service with rekognition behavior
    /// - When:
    ///    - I invoke rekognition api in predictions service
    /// - Then:
    ///    - I should get back a result
    ///
    func testIdentifyModerationLabelsService() {
        setUpAmplify()

        let resultReceived = expectation(description: "Transcription result should be returned")
        let mockResponse: AWSRekognitionDetectModerationLabelsResponse = AWSRekognitionDetectModerationLabelsResponse()
        mockResponse.moderationLabels = [AWSRekognitionModerationLabel]()

        mockRekognition.setModerationLabelsResponse(result: mockResponse)
        let testBundle = Bundle(for: type(of: self))
        guard let url = testBundle.url(forResource: "testImageLabels", withExtension: "jpg") else {
            XCTFail("Unable to find image")
            return
        }

        predictionsService.detectLabels(image: url, type: .moderation) { event in
            switch event {
            case .completed(let result):
                let labelResult = result as? IdentifyLabelsResult
                let labels = IdentifyLabelsResultTransformers.processModerationLabels(mockResponse.moderationLabels!)
                XCTAssertEqual(labelResult?.labels, labels, "Labels should be the same")
                XCTAssertNotNil(labelResult?.unsafeContent,
                                "unsafe content should have a boolean in it since we called moderation labels")
                resultReceived.fulfill()
            case .failed(let error):
                XCTFail("Should not produce error: \(error)")
            }
        }

        waitForExpectations(timeout: 1)
    }

    /// Test whether error is prograted correctly when making a rekognition call to identify moderation labels
    ///
    /// - Given: Predictions service with rekognition behavior
    /// - When:
    ///    - I invoke rekognition api in predictions service
    /// - Then:
    ///    - I should get back a service error
    ///
    func testIdentifyModerationLabelsServiceWithError() {
        setUpAmplify()

        let errorReceived = expectation(description: "Error should be returned")
        let mockError = NSError(domain: AWSRekognitionErrorDomain,
                                code: AWSRekognitionErrorType.invalidImageFormat.rawValue,
                                userInfo: [:])
        mockRekognition.setError(error: mockError)
        let url = URL(fileURLWithPath: "")

        predictionsService.detectLabels(image: url, type: .moderation) { event in
            switch event {
            case .completed(let result):
                XCTFail("Should not produce result: \(result)")
            case .failed(let error):
                XCTAssertNotNil(error, "Should produce an error")
                errorReceived.fulfill()
            }
        }

        waitForExpectations(timeout: 1)
    }

    /// Test whether we can make a successful rekognition call to identify moderation labels but receive a nil response
    ///
    /// - Given: Predictions service with rekognition behavior
    /// - When:
    ///    - I invoke rekognition api in predictions service
    /// - Then:
    ///    - I should get back a service error because response is nil
    ///
    func testIdentifyModerationLabelsServiceWithNilResponse() {
        setUpAmplify()
        mockRekognition.setModerationLabelsResponse(result: nil)

        let errorReceived = expectation(description: "Error should be returned")
        let testBundle = Bundle(for: type(of: self))
        guard let url = testBundle.url(forResource: "testImageLabels", withExtension: "jpg") else {
            XCTFail("Unable to find image")
            return
        }

        predictionsService.detectLabels(image: url, type: .moderation) { event in
            switch event {
            case .completed(let result):
                XCTFail("Should not produce result: \(result)")
            case .failed(let error):
                XCTAssertNotNil(error, "Should produce an error")
                errorReceived.fulfill()
            }
        }

        waitForExpectations(timeout: 1)
    }

    /// Test whether we can make a successful rekognition call to identify all labels
    ///
    /// - Given: Predictions service with rekognition behavior
    /// - When:
    ///    - I invoke rekognition api in predictions service
    /// - Then:
    ///    - I should get back a result
    ///
    func testIdentifyAllLabelsService() {
        setUpAmplify()

        let resultReceived = expectation(description: "Transcription result should be returned")
        let mockLabelsResponse: AWSRekognitionDetectLabelsResponse = AWSRekognitionDetectLabelsResponse()
        mockLabelsResponse.labels = [AWSRekognitionLabel]()

        let mockModerationResponse: AWSRekognitionDetectModerationLabelsResponse =
            AWSRekognitionDetectModerationLabelsResponse()
        mockModerationResponse.moderationLabels = [AWSRekognitionModerationLabel]()

        mockRekognition.setAllLabelsResponse(labelsResult: mockLabelsResponse, moderationResult: mockModerationResponse)
        let testBundle = Bundle(for: type(of: self))
        guard let url = testBundle.url(forResource: "testImageLabels", withExtension: "jpg") else {
            XCTFail("Unable to find image")
            return
        }

        predictionsService.detectLabels(image: url, type: .all) { event in
            switch event {
            case .completed(let result):
                let labelResult = result as? IdentifyLabelsResult
                let labels = IdentifyLabelsResultTransformers.processLabels(mockLabelsResponse.labels!)
                XCTAssertEqual(labelResult?.labels, labels, "Labels should be the same")
                XCTAssertNotNil(labelResult?.unsafeContent,
                                "unsafe content should have a boolean in it since we called all labels")
                resultReceived.fulfill()
            case .failed(let error):
                XCTFail("Should not produce error: \(error)")
            }
        }

        waitForExpectations(timeout: 1)
    }

    /// Test whether error is prograted correctly when making a rekognition call to identify all labels
    ///
    /// - Given: Predictions service with rekognition behavior
    /// - When:
    ///    - I invoke rekognition api in predictions service
    /// - Then:
    ///    - I should get back a service error because response is nil
    ///
    func testIdentifyAllLabelsServiceWithNilResponse() {
        setUpAmplify()

        mockRekognition.setAllLabelsResponse(labelsResult: nil, moderationResult: nil)

        let testBundle = Bundle(for: type(of: self))
        guard let url = testBundle.url(forResource: "testImageLabels", withExtension: "jpg") else {
            XCTFail("Unable to find image")
            return
        }

        let errorReceived = expectation(description: "Error should be returned")

        predictionsService.detectLabels(image: url, type: .all) { event in
            switch event {
            case .completed(let result):
                XCTFail("Should not produce result: \(result)")
            case .failed(let error):
                XCTAssertNotNil(error, "Should produce an error")
                errorReceived.fulfill()
            }
        }

        waitForExpectations(timeout: 1)
    }

    /// Test whether error is prograted correctly when making a rekognition call to identify all labels
    ///
    /// - Given: Predictions service with rekognition behavior
    /// - When:
    ///    - I invoke rekognition api in predictions service
    ///    - Set mockLabelsResponse as labelsResult, set moderationResult to be nil
    /// - Then:
    ///    - I should get back a service error because moderation response is nil
    ///
    func testIdentifyAllLabelsServiceWithNilModerationResponse() {
        setUpAmplify()

        let mockLabelsResponse: AWSRekognitionDetectLabelsResponse = AWSRekognitionDetectLabelsResponse()
        mockLabelsResponse.labels = [AWSRekognitionLabel]()

        mockRekognition.setAllLabelsResponse(labelsResult: mockLabelsResponse, moderationResult: nil)

        let testBundle = Bundle(for: type(of: self))
        guard let url = testBundle.url(forResource: "testImageLabels", withExtension: "jpg") else {
            XCTFail("Unable to find image")
            return
        }
        let errorReceived = expectation(description: "Error should be returned")

        predictionsService.detectLabels(image: url, type: .all) { event in
            switch event {
            case .completed(let result):
                XCTFail("Should not produce result: \(result)")
            case .failed(let error):
                XCTAssertNotNil(error, "Should produce an error")
                errorReceived.fulfill()
            }
        }

        waitForExpectations(timeout: 1)
    }

    /// Test whether error is prograted correctly when making a rekognition call to identify all labels
    ///
    /// - Given: Predictions service with rekognition behavior
    /// - When:
    ///    - I invoke rekognition api in predictions service
    /// - Then:
    ///    - I should get back a service error
    ///
    func testIdentifyAllLabelsServiceWithError() {
        setUpAmplify()

        let mockError = NSError(domain: AWSRekognitionErrorDomain,
                                code: AWSRekognitionErrorType.invalidImageFormat.rawValue,
                                userInfo: [:])
        mockRekognition.setError(error: mockError)
        let url = URL(fileURLWithPath: "")
        let errorReceived = expectation(description: "Error should be returned")

        predictionsService.detectLabels(image: url, type: .all) { event in
            switch event {
            case .completed(let result):
                XCTFail("Should not produce result: \(result)")
            case .failed(let error):
                XCTAssertNotNil(error, "Should produce an error")
                errorReceived.fulfill()
            }
        }

        waitForExpectations(timeout: 1)
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

        let resultReceived = expectation(description: "Transcription result should be returned")

        predictionsService.detectEntities(image: url) { event in
            switch event {
            case .completed(let result):
                let entitiesResult = result as? IdentifyEntitiesResult
                let newFaces = IdentifyEntitiesResultTransformers.processFaces(mockResponse.faceDetails!)
                XCTAssertEqual(entitiesResult?.entities.count, newFaces.count, "Faces count number should be the same")
                resultReceived.fulfill()
            case .failed(let error):
                XCTFail("Should not produce error: \(error)")
            }
        }

        waitForExpectations(timeout: 1)
    }

    /// Test whether error is correctly propogated for detecting entities
    ///
    /// - Given: Predictions service with rekogniton behavior
    /// - When:
    ///    - I invoke an invalid request
    /// - Then:
    ///    - I should get back a service error
    ///
    func testIdentifyEntitiesServiceWithError() {
        setUpAmplify()

        let mockError = NSError(domain: AWSRekognitionErrorDomain,
                                code: AWSRekognitionErrorType.invalidImageFormat.rawValue,
                                userInfo: [:])
        mockRekognition.setError(error: mockError)
        let url = URL(fileURLWithPath: "")
        let errorReceived = expectation(description: "Error should be returned")

        predictionsService.detectEntities(image: url) { event in
            switch event {
            case .completed(let result):
                XCTFail("Should not produce result: \(result)")
            case .failed(let error):
                XCTAssertNotNil(error, "Should produce an error")
                errorReceived.fulfill()
            }
        }

        waitForExpectations(timeout: 1)
    }

    /// Test whether error is correctly propogated for detecting entities when a nil response is received
    ///
    /// - Given: Predictions service with rekogniton behavior
    /// - When:
    ///    - I invoke an nil request
    /// - Then:
    ///    - I should get back a service error because response is nil
    ///
    func testIdentifyEntitiesServiceWithNilResponse() {
        setUpAmplify()
        mockRekognition.setFacesResponse(result: nil)

        let testBundle = Bundle(for: type(of: self))
        guard let url = testBundle.url(forResource: "testImageEntities", withExtension: "jpg") else {
            XCTFail("Unable to find image")
            return
        }
        let errorReceived = expectation(description: "Error should be returned")

        predictionsService.detectEntities(image: url) { event in
            switch event {
            case .completed(let result):
                XCTFail("Should not produce result: \(result)")
            case .failed(let error):
                XCTAssertNotNil(error, "Should produce an error")
                errorReceived.fulfill()
            }
        }

        waitForExpectations(timeout: 1)
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
        let resultReceived = expectation(description: "Transcription result should be returned")

        predictionsService.detectEntities(image: url) { event in
            switch event {
            case .completed(let result):
                let entitiesResult = result as? IdentifyEntityMatchesResult
                let newFaces = IdentifyEntitiesResultTransformers.processCollectionFaces(mockResponse.faceMatches!)
                XCTAssertEqual(entitiesResult?.entities.count, newFaces.count, "Faces count number should be the same")
                resultReceived.fulfill()
            case .failed(let error):
                XCTFail("Should not produce error: \(error)")
            }
        }

        waitForExpectations(timeout: 1)
    }

    /// Test whether error is correctly propogated for entity matches
    ///
    /// - Given: Predictions service with rekogniton behavior
    /// - When:
    ///    - I invoke an invalid request
    /// - Then:
    ///    - I should get back a service error
    ///
    func testIdentifyEntityMatchesServiceWithError() {
        setUpAmplify(withCollection: true)

        let mockError = NSError(domain: AWSRekognitionErrorDomain,
                                code: AWSRekognitionErrorType.invalidImageFormat.rawValue,
                                userInfo: [:])
        mockRekognition.setError(error: mockError)
        let url = URL(fileURLWithPath: "")
        let errorReceived = expectation(description: "Error should be returned")

        predictionsService.detectEntities(image: url) { event in
            switch event {
            case .completed(let result):
                XCTFail("Should not produce result: \(result)")
            case .failed(let error):
                XCTAssertNotNil(error, "Should produce an error")
                errorReceived.fulfill()
            }
        }

        waitForExpectations(timeout: 1)
    }

    /// Test whether error is correctly propogated for entity matches when request is nil
    ///
    /// - Given: Predictions service with rekogniton behavior
    /// - When:
    ///    - I invoke a valid request
    /// - Then:
    ///    - I should get back a service error and nil response
    ///
    func testIdentifyEntityMatchesServiceWithNilResponse() {
        setUpAmplify(withCollection: true)
        mockRekognition.setFacesFromCollection(result: nil)

        let testBundle = Bundle(for: type(of: self))
        guard let url = testBundle.url(forResource: "testImageEntities", withExtension: "jpg") else {
            XCTFail("Unable to find image")
            return
        }
        let errorReceived = expectation(description: "Error should be returned")

        predictionsService.detectEntities(image: url) { event in
            switch event {
            case .completed(let result):
                XCTFail("Should not produce result: \(result)")
            case .failed(let error):
                XCTAssertNotNil(error, "Should produce an error")
                errorReceived.fulfill()
            }
        }

        waitForExpectations(timeout: 1)
    }

    /// Test whether we can make a successfull rekognition call to identify plain text
    ///
    /// - Given: Predictions service with rekognition behavior
    /// - When:
    ///    - I invoke rekognition api in predictions service
    /// - Then:
    ///    - I should get back a result
    ///
    func testIdentifyPlainTextService() {
        setUpAmplify()

        let mockResponse: AWSRekognitionDetectTextResponse = AWSRekognitionDetectTextResponse()
        mockResponse.textDetections = [AWSRekognitionTextDetection]()

        mockRekognition.setText(result: mockResponse)
        let testBundle = Bundle(for: type(of: self))
        guard let url = testBundle.url(forResource: "testImageText", withExtension: "jpg") else {
            XCTFail("Unable to find image")
            return
        }
        let resultReceived = expectation(description: "Transcription result should be returned")

        predictionsService.detectText(image: url, format: .plain) { event in
            switch event {
            case .completed(let result):
                let textResult = result as? IdentifyTextResult
                let newText = IdentifyTextResultTransformers.processText(mockResponse.textDetections!)
                XCTAssertEqual(textResult?.identifiedLines?.count,
                               newText.identifiedLines?.count, "Text line count number should be the same")
                resultReceived.fulfill()
            case .failed(let error):
                XCTFail("Should not produce error: \(error)")
            }
        }

        waitForExpectations(timeout: 1)
    }

    /// Test whether error is correctly propogated for text matches
    ///
    /// - Given: Predictions service with rekogniton behavior
    /// - When:
    ///    - I invoke an invalid request
    /// - Then:
    ///    - I should get back a service error
    ///
    func testIdentifyPlainTextServiceWithError() {
        setUpAmplify()

        let mockError = NSError(domain: AWSRekognitionErrorDomain,
                                code: AWSRekognitionErrorType.invalidImageFormat.rawValue,
                                userInfo: [:])
        mockRekognition.setError(error: mockError)
        let url = URL(fileURLWithPath: "")
        let errorReceived = expectation(description: "Error should be returned")

        predictionsService.detectText(image: url, format: .plain) { event in
            switch event {
            case .completed(let result):
                XCTFail("Should not produce result: \(result)")
            case .failed(let error):
                XCTAssertNotNil(error, "Should produce an error")
                errorReceived.fulfill()
            }
        }

        waitForExpectations(timeout: 1)
    }

    /// Test whether error is correctly propogated for text matches and receive a nil response
    ///
    /// - Given: Predictions service with rekogniton behavior
    /// - When:
    ///    - I invoke a valid request
    /// - Then:
    ///    - I should get back a service error because there was a nil response
    ///
    func testIdentifyPlainTextServiceWithNilResponse() {
        setUpAmplify()

        mockRekognition.setText(result: nil)
        let testBundle = Bundle(for: type(of: self))
        guard let url = testBundle.url(forResource: "testImageText", withExtension: "jpg") else {
            XCTFail("Unable to find image")
            return
        }
        let errorReceived = expectation(description: "Error should be returned")

        predictionsService.detectText(image: url, format: .plain) { event in
            switch event {
            case .completed(let result):
                XCTFail("Should not produce result: \(result)")
            case .failed(let error):
                XCTAssertNotNil(error, "Should produce an error")
                errorReceived.fulfill()
            }
        }

        waitForExpectations(timeout: 1)
    }
}
