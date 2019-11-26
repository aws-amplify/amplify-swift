//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import AWSCore
import AWSRekognition
@testable import AWSPredictionsPlugin

class MockRekognitionBehavior: AWSRekognitionBehavior {

    var celebritiesResponse: AWSRekognitionRecognizeCelebritiesResponse?
    var facesResponse: AWSRekognitionDetectFacesResponse?
    var moderationLabelsResponse: AWSRekognitionDetectModerationLabelsResponse?
    var facesFromCollection: AWSRekognitionSearchFacesByImageResponse?
    var detectLabels: AWSRekognitionDetectLabelsResponse?
    var detectText: AWSRekognitionDetectTextResponse?
    var error: PredictionsError?

    func detectCelebs(request: AWSRekognitionRecognizeCelebritiesRequest)
        -> AWSTask<AWSRekognitionRecognizeCelebritiesResponse> {
            if let finalResult = celebritiesResponse {
                return AWSTask(result: finalResult)
            }
            return AWSTask(error: error!)
    }

    func detectFaces(request: AWSRekognitionDetectFacesRequest)
        -> AWSTask<AWSRekognitionDetectFacesResponse> {
            if let finalResult = facesResponse {
                return AWSTask(result: finalResult)
            }
            return AWSTask(error: error!)
    }

    func detectModerationLabels(request: AWSRekognitionDetectModerationLabelsRequest)
        -> AWSTask<AWSRekognitionDetectModerationLabelsResponse> {
            if let finalResult = moderationLabelsResponse {
                return AWSTask(result: finalResult)
            }
            return AWSTask(error: error!)
    }

    func detectFacesFromCollection(request: AWSRekognitionSearchFacesByImageRequest)
        -> AWSTask<AWSRekognitionSearchFacesByImageResponse> {
            if let finalResult = facesFromCollection {
                return AWSTask(result: finalResult)
            }
            return AWSTask(error: error!)
    }

    func detectLabels(request: AWSRekognitionDetectLabelsRequest) -> AWSTask<AWSRekognitionDetectLabelsResponse> {
        if let finalResult = detectLabels {
            return AWSTask(result: finalResult)
        }
        return AWSTask(error: error!)
    }

    func detectText(request: AWSRekognitionDetectTextRequest) -> AWSTask<AWSRekognitionDetectTextResponse> {
        if let finalResult = detectText {
            return AWSTask(result: finalResult)
        }
        return AWSTask(error: error!)
    }

    func getRekognition() -> AWSRekognition {
        return AWSRekognition()
    }

    public func setDetectCelebs(result: AWSRekognitionRecognizeCelebritiesResponse) {
        celebritiesResponse = result
        error = nil
    }

    public func setFacesResponse(result: AWSRekognitionDetectFacesResponse) {
        facesResponse = result
        error = nil
    }

    public func setModerationLabelsResponse(result: AWSRekognitionDetectModerationLabelsResponse) {
        moderationLabelsResponse = result
        error = nil
    }

    public func setFacesFromCollection(result: AWSRekognitionSearchFacesByImageResponse) {
        facesFromCollection = result
        error = nil
    }

    public func setError(error: PredictionsError) {
        celebritiesResponse = nil
        facesResponse = nil
        moderationLabelsResponse = nil
        facesFromCollection = nil
        detectText = nil
        detectLabels = nil
        self.error = error
    }
}
