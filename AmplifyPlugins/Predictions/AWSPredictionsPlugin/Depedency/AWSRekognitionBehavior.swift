//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import AWSRekognition

protocol AWSRekognitionBehavior {
    func detectLabels(
        request: DetectLabelsInput
    ) async throws -> DetectLabelsOutputResponse

    func detectModerationLabels(
        request: DetectModerationLabelsInput
    ) async throws -> DetectModerationLabelsOutputResponse

    func detectCelebrities(
        request: RecognizeCelebritiesInput
    ) async throws -> RecognizeCelebritiesOutputResponse

    func detectText(
        request: DetectTextInput
    ) async throws -> DetectTextOutputResponse

    func detectFaces(
        request: DetectFacesInput
    ) async throws -> DetectFacesOutputResponse

    func detectFacesFromCollection(
        request: SearchFacesByImageInput
    ) async throws -> SearchFacesByImageOutputResponse

    func getRekognition() async throws -> RekognitionClient
}
