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
    var mockRekognition = MockRekognitionBehavior()
    var mockConfigurationJSON = """
    {
        "defaultRegion": "us-west-2"
    }
    """

    let mockError = NSError(
        domain: "aws.rekognition.errordomain",
        code: 42,
        userInfo: [:]
    )

    func url(_ resource: String) throws -> URL {
        let testBundle = Bundle.module
        return try XCTUnwrap(
            testBundle.url(forResource: resource, withExtension: "jpg", subdirectory: "TestImages"),
            "Unable to find resource: \(resource)"
        )
    }

    override func setUp() {}

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
            let mockConfiguration = try JSONDecoder().decode(
                PredictionsPluginConfiguration.self,
                from: Data(mockConfigurationJSON.utf8)
            )

            predictionsService = AWSPredictionsService(
                identifier: "",
                awsTranslate: MockTranslateBehavior(),
                awsRekognition: mockRekognition,
                awsTextract: MockTextractBehavior(),
                awsComprehend: MockComprehendBehavior(),
                awsPolly: MockPollyBehavior(),
                configuration: mockConfiguration
            )
        } catch {
            XCTFail("Initialization of the text failed with error: \(error)")
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
    func testIdentifyLabelsService() async throws {
        setUpAmplify()
        let mockResponse = DetectLabelsOutputResponse(labels: [])
        mockRekognition.detectLabelsResponse = { _ in mockResponse }
        let url = try url("testImageLabels")

        let result = try await predictionsService.detectLabels(image: url, type: .labels)
        let labels = IdentifyLabelsResultTransformers.processLabels(mockResponse.labels!)
        XCTAssertEqual(result.labels, labels, "Labels should be the same")
    }

    /// Test whether error is correctly propogated
    ///
    /// - Given: Predictions service with rekogniton behavior
    /// - When:
    ///    - I invoke an invalid request
    /// - Then:
    ///    - I should get back a service error
    ///
    func testIdentifyLabelsServiceWithError() async throws {
        setUpAmplify()
        mockRekognition.detectLabelsResponse = { _ in throw self.mockError }
        let url = URL(fileURLWithPath: "")

        do {
            let result = try await predictionsService.detectLabels(image: url, type: .labels)
            XCTFail("Should not produce result: \(result)")
        } catch {
            XCTAssertNotNil(error, "Should produce an error")
        }
    }

    /// Test whether we can make a successful rekognition call to identify moderation labels
    ///
    /// - Given: Predictions service with rekognition behavior
    /// - When:
    ///    - I invoke rekognition api in predictions service
    /// - Then:
    ///    - I should get back a result
    ///
    func testIdentifyModerationLabelsService() async throws {
        setUpAmplify()
        let mockResponse = DetectModerationLabelsOutputResponse(moderationLabels: [])
        mockRekognition.moderationLabelsResponse = { _ in mockResponse }
        let url = try url("testImageLabels")

        let result = try await predictionsService.detectLabels(image: url, type: .moderation)
        let labels = IdentifyLabelsResultTransformers.processModerationLabels(mockResponse.moderationLabels!)
        XCTAssertEqual(result.labels, labels, "Labels should be the same")
        XCTAssertNotNil(
            result.unsafeContent,
            "unsafe content should have a boolean in it since we called moderation labels"
        )
    }

    /// Test whether error is prograted correctly when making a rekognition call to identify moderation labels
    ///
    /// - Given: Predictions service with rekognition behavior
    /// - When:
    ///    - I invoke rekognition api in predictions service
    /// - Then:
    ///    - I should get back a service error
    ///
    func testIdentifyModerationLabelsServiceWithError() async throws {
        setUpAmplify()
        mockRekognition.moderationLabelsResponse = { _ in throw self.mockError }
        let url = URL(fileURLWithPath: "")

        do {
            let result = try await predictionsService.detectLabels(image: url, type: .moderation)
            XCTFail("Should not produce result: \(result)")
        } catch {
            XCTAssertNotNil(error, "Should produce an error")
        }
    }

    /// Test whether we can make a successful rekognition call to identify all labels
    ///
    /// - Given: Predictions service with rekognition behavior
    /// - When:
    ///    - I invoke rekognition api in predictions service
    /// - Then:
    ///    - I should get back a result
    ///
    func testIdentifyAllLabelsService() async throws {
        setUpAmplify()
        let mockLabelsResponse = DetectLabelsOutputResponse(labels: [])
        let mockModerationResponse = DetectModerationLabelsOutputResponse(moderationLabels: [])
        mockRekognition.detectLabelsResponse = { _ in mockLabelsResponse }
        mockRekognition.moderationLabelsResponse = { _ in mockModerationResponse }
        let url = try url("testImageLabels")

        let result = try await predictionsService.detectLabels(image: url, type: .all)
        let labels = IdentifyLabelsResultTransformers.processLabels(mockLabelsResponse.labels!)
        XCTAssertEqual(result.labels, labels, "Labels should be the same")
        XCTAssertNotNil(
            result.unsafeContent,
            "unsafe content should have a boolean in it since we called all labels"
        )
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
    func testIdentifyAllLabelsServiceWithNilModerationResponse() async throws {
        setUpAmplify()
        let mockLabelsResponse = DetectLabelsOutputResponse(labels: [])
        mockRekognition.detectLabelsResponse = { _ in mockLabelsResponse }
        let url = try url("testImageLabels")

        do {
            let result = try await predictionsService.detectLabels(image: url, type: .all)
            XCTFail("Should not produce result: \(result)")
        } catch {
            XCTAssertNotNil(error, "Should produce an error")
        }
    }

    /// Test whether error is prograted correctly when making a rekognition call to identify all labels
    ///
    /// - Given: Predictions service with rekognition behavior
    /// - When:
    ///    - I invoke rekognition api in predictions service
    /// - Then:
    ///    - I should get back a service error
    ///
    func testIdentifyAllLabelsServiceWithError() async throws {
        setUpAmplify()
        mockRekognition.detectLabelsResponse = { _ in throw self.mockError }
        let url = URL(fileURLWithPath: "")

        do {
            let result = try await predictionsService.detectLabels(image: url, type: .all)
            XCTFail("Should not produce result: \(result)")
        } catch {
            XCTAssertNotNil(error, "Should produce an error")
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
    func testIdentifyEntitiesService() async throws {
        setUpAmplify()
        let mockResponse = DetectFacesOutputResponse(faceDetails: [])
        mockRekognition.facesResponse = { _ in mockResponse }
        let url = try url("testImageEntities")

        let result = try await predictionsService.detectEntities(image: url)
        let newFaces = IdentifyEntitiesResultTransformers.processFaces(mockResponse.faceDetails!)
        XCTAssertEqual(
            result.entities.count,
            newFaces.count, "Faces count number should be the same"
        )
    }

    /// Test whether error is correctly propogated for detecting entities
    ///
    /// - Given: Predictions service with rekogniton behavior
    /// - When:
    ///    - I invoke an invalid request
    /// - Then:
    ///    - I should get back a service error
    ///
    func testIdentifyEntitiesServiceWithError() async throws {
        setUpAmplify()
        mockRekognition.detectTextResponse = { _ in throw self.mockError }
        let url = URL(fileURLWithPath: "")

        do {
            let result = try await predictionsService.detectEntities(image: url)
            XCTFail("Should not produce result: \(result)")
        } catch {
            XCTAssertNotNil(error, "Should produce an error")
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
    func testIdentifyEntityMatchesService()  async throws {
        setUpAmplify(withCollection: true)
        let mockResponse = SearchFacesByImageOutputResponse(faceMatches: [])
        mockRekognition.facesFromCollectionResponse = { _ in mockResponse }
        let url = try url("testImageEntities")
        let collectionID = try XCTUnwrap(predictionsService.predictionsConfig.identify.identifyEntities?.collectionId)
        let result = try await predictionsService.detectEntitiesCollection(image: url, collectionID: collectionID) //detectEntities(image: url)
        let newFaces = IdentifyEntitiesResultTransformers.processCollectionFaces(mockResponse.faceMatches!)
        XCTAssertEqual(result.entities.count, newFaces.count, "Faces count number should be the same")
    }

    /// Test whether error is correctly propogated for entity matches
    ///
    /// - Given: Predictions service with rekogniton behavior
    /// - When:
    ///    - I invoke an invalid request
    /// - Then:
    ///    - I should get back a service error
    ///
    func testIdentifyEntityMatchesServiceWithError() async throws {
        setUpAmplify(withCollection: true)
        mockRekognition.facesFromCollectionResponse = { _ in throw self.mockError }
        let url = URL(fileURLWithPath: "")

        do {
            let result = try await predictionsService.detectEntities(image: url)
            XCTFail("Should not produce result: \(result)")
        } catch {
            XCTAssertNotNil(error, "Should produce an error")
        }
    }

    /// Test whether we can make a successfull rekognition call to identify plain text
    ///
    /// - Given: Predictions service with rekognition behavior
    /// - When:
    ///    - I invoke rekognition api in predictions service
    /// - Then:
    ///    - I should get back a result
    ///
    func testIdentifyPlainTextService() async throws {
        setUpAmplify()
        let mockResponse = DetectTextOutputResponse(textDetections: [])
        mockRekognition.detectTextResponse = { _ in mockResponse }
        let url = try url("testImageText")
        let result = try await predictionsService.detectPlainText(image: url)

        let newText = IdentifyTextResultTransformers.processText(mockResponse.textDetections!)
        XCTAssertEqual(
            result.identifiedLines?.count,
            newText.identifiedLines?.count,
            "Text line count number should be the same"
        )
    }

    /// Test whether error is correctly propogated for text matches
    ///
    /// - Given: Predictions service with rekogniton behavior
    /// - When:
    ///    - I invoke an invalid request
    /// - Then:
    ///    - I should get back a service error
    ///
    func testIdentifyPlainTextServiceWithError() async throws {
        setUpAmplify()
        mockRekognition.detectTextResponse = { _ in throw self.mockError }
        let url = URL(fileURLWithPath: "")

        do {
            let result = try await predictionsService.detectPlainText(image: url)
            XCTFail("Should not produce result: \(result)")
        } catch {
            XCTAssertNotNil(error, "Should produce an error")
        }
    }
}


/// Test whether error is correctly propogated for text matches and receive a nil response
///
/// - Given: Predictions service with rekogniton behavior
/// - When:
///    - I invoke a valid request
/// - Then:
///    - I should get back a service error because there was a nil response
///
//    func testIdentifyPlainTextServiceWithNilResponse() {
//        setUpAmplify()
//
//        mockRekognition.setText(result: nil)
//        let testBundle = Bundle(for: type(of: self))
//        guard let url = testBundle.url(forResource: "testImageText", withExtension: "jpg") else {
//            XCTFail("Unable to find image")
//            return
//        }
//        let errorReceived = expectation(description: "Error should be returned")
//
//        predictionsService.detectText(image: url, format: .plain) { event in
//            switch event {
//            case .completed(let result):
//                XCTFail("Should not produce result: \(result)")
//            case .failed(let error):
//                XCTAssertNotNil(error, "Should produce an error")
//                errorReceived.fulfill()
//            }
//        }
//
//        waitForExpectations(timeout: 1)
//    }

/// Test whether error is correctly propogated for entity matches when request is nil
///
/// - Given: Predictions service with rekogniton behavior
/// - When:
///    - I invoke a valid request
/// - Then:
///    - I should get back a service error and nil response
///
//    func testIdentifyEntityMatchesServiceWithNilResponse() {
//        setUpAmplify(withCollection: true)
//        mockRekognition.setFacesFromCollection(result: nil)
//
//        let testBundle = Bundle(for: type(of: self))
//        guard let url = testBundle.url(forResource: "testImageEntities", withExtension: "jpg") else {
//            XCTFail("Unable to find image")
//            return
//        }
//        let errorReceived = expectation(description: "Error should be returned")
//
//        predictionsService.detectEntities(image: url) { event in
//            switch event {
//            case .completed(let result):
//                XCTFail("Should not produce result: \(result)")
//            case .failed(let error):
//                XCTAssertNotNil(error, "Should produce an error")
//                errorReceived.fulfill()
//            }
//        }
//
//        waitForExpectations(timeout: 1)
//    }

/// Test whether error is correctly propogated for detecting entities when a nil response is received
///
/// - Given: Predictions service with rekogniton behavior
/// - When:
///    - I invoke an nil request
/// - Then:
///    - I should get back a service error because response is nil
///
//    func testIdentifyEntitiesServiceWithNilResponse() {
//        setUpAmplify()
//        mockRekognition.setFacesResponse(result: nil)
//
//        let testBundle = Bundle(for: type(of: self))
//        guard let url = testBundle.url(forResource: "testImageEntities", withExtension: "jpg") else {
//            XCTFail("Unable to find image")
//            return
//        }
//        let errorReceived = expectation(description: "Error should be returned")
//
//        predictionsService.detectEntities(image: url) { event in
//            switch event {
//            case .completed(let result):
//                XCTFail("Should not produce result: \(result)")
//            case .failed(let error):
//                XCTAssertNotNil(error, "Should produce an error")
//                errorReceived.fulfill()
//            }
//        }
//
//        waitForExpectations(timeout: 1)
//    }

/// Test whether error is prograted correctly when making a rekognition call to identify all labels
///
/// - Given: Predictions service with rekognition behavior
/// - When:
///    - I invoke rekognition api in predictions service
/// - Then:
///    - I should get back a service error because response is nil
///
//    func testIdentifyAllLabelsServiceWithNilResponse() {
//        setUpAmplify()
//
//        mockRekognition.setAllLabelsResponse(labelsResult: nil, moderationResult: nil)
//
//        let testBundle = Bundle(for: type(of: self))
//        guard let url = testBundle.url(forResource: "testImageLabels", withExtension: "jpg") else {
//            XCTFail("Unable to find image")
//            return
//        }
//
//        let errorReceived = expectation(description: "Error should be returned")
//
//        predictionsService.detectLabels(image: url, type: .all) { event in
//            switch event {
//            case .completed(let result):
//                XCTFail("Should not produce result: \(result)")
//            case .failed(let error):
//                XCTAssertNotNil(error, "Should produce an error")
//                errorReceived.fulfill()
//            }
//        }
//
//        waitForExpectations(timeout: 1)
//    }
/// Test whether error is correctly propogated
///
/// - Given: Predictions service with rekogniton behavior
/// - When:
///    - I invoke an invalid request
/// - Then:
///    - I should get back a service error because response was nil
///
//    func testIdentifyLabelsServiceWithNilResponse() {
//        setUpAmplify()
//
//
//        mockRekognition.setLabelsResponse(result: nil)
//
//        let errorReceived = expectation(description: "Error should be returned")
//        let testBundle = Bundle(for: type(of: self))
//        guard let url = testBundle.url(forResource: "testImageLabels", withExtension: "jpg") else {
//            XCTFail("Unable to find image")
//            return
//        }
//
//        predictionsService.detectLabels(image: url, type: .labels) { event in
//            switch event {
//            case .completed(let result):
//                XCTFail("Should not produce result: \(result)")
//            case .failed(let error):
//                XCTAssertNotNil(error, "Should produce an error")
//                errorReceived.fulfill()
//            }
//        }
//
//        waitForExpectations(timeout: 1)
//    }
/// Test whether we can make a successful rekognition call to identify moderation labels but receive a nil response
///
/// - Given: Predictions service with rekognition behavior
/// - When:
///    - I invoke rekognition api in predictions service
/// - Then:
///    - I should get back a service error because response is nil
///
//    func testIdentifyModerationLabelsServiceWithNilResponse() {
//        setUpAmplify()
//
//        mockRekognition.setModerationLabelsResponse(result: nil)
//
//        let errorReceived = expectation(description: "Error should be returned")
//        let testBundle = Bundle(for: type(of: self))
//        guard let url = testBundle.url(forResource: "testImageLabels", withExtension: "jpg") else {
//            XCTFail("Unable to find image")
//            return
//        }
//
//        predictionsService.detectLabels(image: url, type: .moderation) { event in
//            switch event {
//            case .completed(let result):
//                XCTFail("Should not produce result: \(result)")
//            case .failed(let error):
//                XCTAssertNotNil(error, "Should produce an error")
//                errorReceived.fulfill()
//            }
//        }
//
//        waitForExpectations(timeout: 1)
//    }
