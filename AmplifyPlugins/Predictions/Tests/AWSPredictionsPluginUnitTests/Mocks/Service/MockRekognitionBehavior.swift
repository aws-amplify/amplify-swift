//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
//import AWSCore
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

    func getRekognition() async throws -> RekognitionClient {
        try await RekognitionClient()
    }

//    init(
//        detectLabelsResponse: @escaping () -> DetectLabelsOutputResponse,
//        moderationLabelsResponse: @escaping () -> DetectModerationLabelsOutputResponse,
//        celebritiesResponse: @escaping () -> RecognizeCelebritiesOutputResponse,
//        detectTextResponse: @escaping () -> DetectTextOutputResponse,
//        facesResponse: @escaping () -> DetectFacesOutputResponse,
//        facesFromCollectionResponse: @escaping () -> SearchFacesByImageOutputResponse
//    ) {
//        self.detectLabelsResponse = detectLabelsResponse
//        self.moderationLabelsResponse = moderationLabelsResponse
//        self.celebritiesResponse = celebritiesResponse
//        self.detectTextResponse = detectTextResponse
//        self.facesResponse = facesResponse
//        self.facesFromCollectionResponse = facesFromCollectionResponse
//    }
}



//var celebritiesResponse: AWSRekognitionRecognizeCelebritiesResponse?
//var facesResponse: AWSRekognitionDetectFacesResponse?
//var moderationLabelsResponse: AWSRekognitionDetectModerationLabelsResponse?
//var facesFromCollection: AWSRekognitionSearchFacesByImageResponse?
//var detectLabels: AWSRekognitionDetectLabelsResponse?
//var detectText: AWSRekognitionDetectTextResponse?
//var error: Error?
//
//func detectCelebs(request: AWSRekognitionRecognizeCelebritiesRequest)
//    -> AWSTask<AWSRekognitionRecognizeCelebritiesResponse> {
//        if let finalResult = celebritiesResponse {
//            return AWSTask(result: finalResult)
//        }
//        return AWSTask(error: error!)
//}
//
//func detectFaces(request: AWSRekognitionDetectFacesRequest)
//    -> AWSTask<AWSRekognitionDetectFacesResponse> {
//        guard let finalError = error else {
//            return AWSTask(result: facesResponse)
//        }
//
//        return AWSTask(error: finalError)
//}
//
//func detectModerationLabels(request: AWSRekognitionDetectModerationLabelsRequest) -> AWSTask<AWSRekognitionDetectModerationLabelsResponse> {
//        guard let finalError = error else {
//            return AWSTask(result: moderationLabelsResponse)
//        }
//        return AWSTask(error: finalError)
//}
//
//func detectFacesFromCollection(request: AWSRekognitionSearchFacesByImageRequest) -> AWSTask<AWSRekognitionSearchFacesByImageResponse> {
//        guard let finalError = error else {
//            return AWSTask(result: facesFromCollection)
//        }
//        return AWSTask(error: finalError)
//}
//
//func detectLabels(request: AWSRekognitionDetectLabelsRequest) -> AWSTask<AWSRekognitionDetectLabelsResponse> {
//    guard let finalError = error else {
//        return AWSTask(result: detectLabels)
//    }
//    return AWSTask(error: finalError)
//}
//
//func detectText(request: AWSRekognitionDetectTextRequest) -> AWSTask<AWSRekognitionDetectTextResponse> {
//    guard let finalError = error else {
//        return AWSTask(result: detectText)
//    }
//    return AWSTask(error: finalError)
//}
//
//func getRekognition() -> AWSRekognition {
//    return AWSRekognition()
//}
//
//public func setDetectCelebs(result: AWSRekognitionRecognizeCelebritiesResponse) {
//    celebritiesResponse = result
//    error = nil
//}
//
//public func setFacesResponse(result: AWSRekognitionDetectFacesResponse?) {
//    facesResponse = result
//    error = nil
//}
//
//public func setModerationLabelsResponse(result: AWSRekognitionDetectModerationLabelsResponse?) {
//    moderationLabelsResponse = result
//    error = nil
//}
//
//public func setLabelsResponse(result: AWSRekognitionDetectLabelsResponse?) {
//    detectLabels = result
//    error = nil
//}
//
//public func setAllLabelsResponse(labelsResult: AWSRekognitionDetectLabelsResponse?,
//                                 moderationResult: AWSRekognitionDetectModerationLabelsResponse?) {
//    detectLabels = labelsResult
//    moderationLabelsResponse = moderationResult
//    error = nil
//}
//
//public func setFacesFromCollection(result: AWSRekognitionSearchFacesByImageResponse?) {
//    facesFromCollection = result
//    error = nil
//}
//
//public func setText(result: AWSRekognitionDetectTextResponse?) {
//    detectText = result
//    error = nil
//}
//
//public func setError(error: Error) {
//    celebritiesResponse = nil
//    facesResponse = nil
//    moderationLabelsResponse = nil
//    facesFromCollection = nil
//    detectText = nil
//    detectLabels = nil
//    self.error = error
//}
