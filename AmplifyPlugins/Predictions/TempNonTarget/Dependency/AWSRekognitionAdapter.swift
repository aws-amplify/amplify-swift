//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import AWSRekognition

class AWSRekognitionAdapter: AWSRekognitionBehavior {

    let awsRekognition: AWSRekognition

    init(_ awsRekognition: AWSRekognition) {
        self.awsRekognition = awsRekognition
    }

    func detectLabels(request: AWSRekognitionDetectLabelsRequest) -> AWSTask<AWSRekognitionDetectLabelsResponse> {
        awsRekognition.detectLabels(request)
    }

    func detectModerationLabels(
        request: AWSRekognitionDetectModerationLabelsRequest) -> AWSTask<AWSRekognitionDetectModerationLabelsResponse> {
        awsRekognition.detectModerationLabels(request)
    }

    func detectCelebs(
        request: AWSRekognitionRecognizeCelebritiesRequest) ->
        AWSTask<AWSRekognitionRecognizeCelebritiesResponse> {
        awsRekognition.recognizeCelebrities(request)
    }

    func detectText(request: AWSRekognitionDetectTextRequest) -> AWSTask<AWSRekognitionDetectTextResponse> {
        awsRekognition.detectText(request)
    }

    func detectFaces(request: AWSRekognitionDetectFacesRequest) -> AWSTask<AWSRekognitionDetectFacesResponse> {
        awsRekognition.detectFaces(request)
    }

    func detectFacesFromCollection(
        request: AWSRekognitionSearchFacesByImageRequest) -> AWSTask<AWSRekognitionSearchFacesByImageResponse> {
        awsRekognition.searchFaces(byImage: request)
    }

    func getRekognition() -> AWSRekognition {
        return awsRekognition
    }

}
