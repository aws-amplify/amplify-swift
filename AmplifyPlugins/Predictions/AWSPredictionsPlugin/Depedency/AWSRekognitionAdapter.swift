//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import AWSRekognition

class AWSRekognitionAdapter: AWSRekognitionBehavior {
    let awsRekognition: RekognitionClient

    init(_ awsRekognition: RekognitionClient) {
        self.awsRekognition = awsRekognition
    }

    func detectLabels(
        request: DetectLabelsInput
    ) async throws -> DetectLabelsOutputResponse {
        try await awsRekognition.detectLabels(input: request)
    }

    func detectModerationLabels(
        request: DetectModerationLabelsInput
    ) async throws -> DetectModerationLabelsOutputResponse {
        try await awsRekognition.detectModerationLabels(input: request)
    }

    func detectCelebrities(
        request: RecognizeCelebritiesInput
    ) async throws -> RecognizeCelebritiesOutputResponse {
        try await awsRekognition.recognizeCelebrities(input: request)
    }

    func detectText(
        request: DetectTextInput
    ) async throws -> DetectTextOutputResponse {
        try await awsRekognition.detectText(input: request)
    }

    func detectFaces(
        request: DetectFacesInput
    ) async throws -> DetectFacesOutputResponse {
        try await awsRekognition.detectFaces(input: request)
    }

    func detectFacesFromCollection(
        request: SearchFacesByImageInput
    ) async throws -> SearchFacesByImageOutputResponse {
        try await awsRekognition.searchFacesByImage(input: request)
    }

    func getRekognition() async throws -> RekognitionClient {
        return awsRekognition
    }

}
