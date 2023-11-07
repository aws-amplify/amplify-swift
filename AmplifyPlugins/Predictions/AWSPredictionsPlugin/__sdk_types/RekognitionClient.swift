//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import AWSPluginsCore

struct RekognitionClient {
    struct Configuration {
        let region: String
        let credentialsProvider: CredentialsProvider
        let signingName = ""
    }

    let configuration: Configuration

    func recognizeCelebrities(input: RecognizeCelebritiesInput) async throws -> RecognizeCelebritiesOutputResponse {
        fatalError()
    }

    func searchFacesByImage(input: SearchFacesByImageInput) async throws -> SearchFacesByImageOutputResponse {
        fatalError()
    }

    func detectFaces(input: DetectFacesInput) async throws -> DetectFacesOutputResponse {
        fatalError()
    }

    func detectText(input: DetectTextInput) async throws -> DetectTextOutputResponse {
        fatalError()
    }

    func detectModerationLabels(input: DetectModerationLabelsInput) async throws -> DetectModerationLabelsOutputResponse {
        fatalError()
    }

    func detectLabels(input: DetectLabelsInput) async throws -> DetectLabelsOutputResponse {
        fatalError()
    }
}
