//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
@testable import AWSPredictionsPlugin

//class MockRekognitionBehavior: RekognitionClient {
//    var detectLabelsResponse: ((DetectLabelsInput) async throws -> DetectLabelsOutputResponse)? = nil
//    var moderationLabelsResponse: ((DetectModerationLabelsInput) async throws -> DetectModerationLabelsOutputResponse)? = nil
//    var celebritiesResponse: ((RecognizeCelebritiesInput) async throws -> RecognizeCelebritiesOutputResponse)? = nil
//    var detectTextResponse: ((DetectTextInput) async throws -> DetectTextOutputResponse)? = nil
//    var facesResponse: ((DetectFacesInput) async throws -> DetectFacesOutputResponse)? = nil
//    var facesFromCollectionResponse: ((SearchFacesByImageInput) async throws -> SearchFacesByImageOutputResponse)? = nil
//
//    func detectLabels(input: DetectLabelsInput) async throws -> DetectLabelsOutputResponse {
//        guard let detectLabelsResponse else { throw MockBehaviorDefaultError() }
//        return try await detectLabelsResponse(input)
//    }
//
//    func detectModerationLabels(input: DetectModerationLabelsInput) async throws -> DetectModerationLabelsOutputResponse {
//        guard let moderationLabelsResponse else { throw MockBehaviorDefaultError() }
//        return try await moderationLabelsResponse(input)
//    }
//
//    func detectCelebrities(input: RecognizeCelebritiesInput) async throws -> RecognizeCelebritiesOutputResponse {
//        guard let celebritiesResponse else { throw MockBehaviorDefaultError() }
//        return try await celebritiesResponse(input)
//    }
//
//    func detectText(input: DetectTextInput) async throws -> DetectTextOutputResponse {
//        guard let detectTextResponse else { throw MockBehaviorDefaultError() }
//        return try await detectTextResponse(input)
//    }
//
//    func detectFaces(input: DetectFacesInput) async throws -> DetectFacesOutputResponse {
//        guard let facesResponse else { throw MockBehaviorDefaultError() }
//        return try await facesResponse(input)
//    }
//
//    func searchFacesByImage(input: SearchFacesByImageInput) async throws -> SearchFacesByImageOutputResponse {
//        guard let facesFromCollectionResponse else { throw MockBehaviorDefaultError() }
//        return try await facesFromCollectionResponse(input)
//    }
//
//    func getRekognition() -> AWSRekognition.RekognitionClient {
//        try! .init(region: "us-east-1")
//    }
//}
