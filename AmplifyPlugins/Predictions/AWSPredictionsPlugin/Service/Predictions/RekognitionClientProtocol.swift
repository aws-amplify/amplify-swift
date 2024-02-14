//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AWSRekognition

public protocol RekognitionClientProtocol {

    func recognizeCelebrities(input: RecognizeCelebritiesInput) async throws -> RecognizeCelebritiesOutput

    func searchFacesByImage(input: SearchFacesByImageInput) async throws -> SearchFacesByImageOutput

    func detectFaces(input: DetectFacesInput) async throws -> DetectFacesOutput

    func detectText(input: DetectTextInput) async throws -> DetectTextOutput

    func detectModerationLabels(input: DetectModerationLabelsInput) async throws -> DetectModerationLabelsOutput

    func detectLabels(input: DetectLabelsInput) async throws -> DetectLabelsOutput


}

extension RekognitionClient: RekognitionClientProtocol { }
