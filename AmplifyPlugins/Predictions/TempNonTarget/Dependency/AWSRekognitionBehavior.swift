//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import AWSRekognition

protocol AWSRekognitionBehavior {

    func detectLabels(request: AWSRekognitionDetectLabelsRequest) -> AWSTask<AWSRekognitionDetectLabelsResponse>

    func detectCelebs(request: AWSRekognitionRecognizeCelebritiesRequest) ->
        AWSTask<AWSRekognitionRecognizeCelebritiesResponse>

    func detectText(request: AWSRekognitionDetectTextRequest) -> AWSTask<AWSRekognitionDetectTextResponse>

    func detectFaces(request: AWSRekognitionDetectFacesRequest) -> AWSTask<AWSRekognitionDetectFacesResponse>

    func detectModerationLabels(
        request: AWSRekognitionDetectModerationLabelsRequest
    ) -> AWSTask<AWSRekognitionDetectModerationLabelsResponse>

    func detectFacesFromCollection(
        request: AWSRekognitionSearchFacesByImageRequest) -> AWSTask<AWSRekognitionSearchFacesByImageResponse>

    func getRekognition() -> AWSRekognition

}
