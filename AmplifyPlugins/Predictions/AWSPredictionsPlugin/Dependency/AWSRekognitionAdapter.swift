//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
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
        return awsRekognition.detectLabels(request)
    }

    func detectCelebs(
        request: AWSRekognitionRecognizeCelebritiesRequest) ->
        AWSTask<AWSRekognitionRecognizeCelebritiesResponse> {
        return awsRekognition.recognizeCelebrities(request)
    }

    func detectText(request: AWSRekognitionDetectTextRequest) -> AWSTask<AWSRekognitionDetectTextResponse> {
        return awsRekognition.detectText(request)
    }

    func detectFaces(request: AWSRekognitionDetectFacesRequest) -> AWSTask<AWSRekognitionDetectFacesResponse> {
        return awsRekognition.detectFaces(request)
    }

    func detectFacesFromCollection(
        request: AWSRekognitionSearchFacesByImageRequest) -> AWSTask<AWSRekognitionSearchFacesByImageResponse> {
        return awsRekognition.searchFaces(byImage: request)
    }

    func getRekognition() -> AWSRekognition {
        return awsRekognition
    }

}
