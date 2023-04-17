//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import AWSRekognition
@testable import AWSPredictionsPlugin

class MockRekognitionBehavior: AWSRekognitionBehavior {
    var detectLabelsResponse: ((DetectLabelsInput) async throws -> DetectLabelsOutputResponse)? = nil
    var moderationLabelsResponse: ((DetectModerationLabelsInput) async throws -> DetectModerationLabelsOutputResponse)? = nil
    var celebritiesResponse: ((RecognizeCelebritiesInput) async throws -> RecognizeCelebritiesOutputResponse)? = nil
    var detectTextResponse: ((DetectTextInput) async throws -> DetectTextOutputResponse)? = nil
    var facesResponse: ((DetectFacesInput) async throws -> DetectFacesOutputResponse)? = nil
    var facesFromCollectionResponse: ((SearchFacesByImageInput) async throws -> SearchFacesByImageOutputResponse)? = nil

    func detectLabels(request: DetectLabelsInput) async throws -> DetectLabelsOutputResponse {
        guard let detectLabelsResponse else { throw MockBehaviorDefaultError() }
        return try await detectLabelsResponse(request)
    }

    func detectModerationLabels(request: DetectModerationLabelsInput) async throws -> DetectModerationLabelsOutputResponse {
        guard let moderationLabelsResponse else { throw MockBehaviorDefaultError() }
        return try await moderationLabelsResponse(request)

    }

    func detectCelebrities(request: RecognizeCelebritiesInput) async throws -> RecognizeCelebritiesOutputResponse {
        guard let celebritiesResponse else { throw MockBehaviorDefaultError() }
        return try await celebritiesResponse(request)
    }

    func detectText(request: DetectTextInput) async throws -> DetectTextOutputResponse {
        guard let detectTextResponse else { throw MockBehaviorDefaultError() }
        return try await detectTextResponse(request)
    }

    func detectFaces(request: DetectFacesInput) async throws -> DetectFacesOutputResponse {
        guard let facesResponse else { throw MockBehaviorDefaultError() }
        return try await facesResponse(request)
    }

    func detectFacesFromCollection(request: SearchFacesByImageInput) async throws -> SearchFacesByImageOutputResponse {
        guard let facesFromCollectionResponse else { throw MockBehaviorDefaultError() }
        return try await facesFromCollectionResponse(request)
    }

    func getRekognition() -> AWSRekognition.RekognitionClient {
        try! .init(region: "us-east-1")
    }
}
