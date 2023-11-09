//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import AWSPluginsCore

struct RekognitionAction<Input: Encodable, Output: Decodable> {
    let name: String
    let method: HTTPMethod
    let requestURI: String
    let successCode: Int
    let hostPrefix: String
    let xAmzTarget: String
    let mapError: (Data, HTTPURLResponse) throws -> Error

    let encode: (Input, JSONEncoder) throws -> Data = { model, encoder in
        try encoder.encode(model)
    }

    let decode: (Data, JSONDecoder) throws -> Output = { data, decoder in
        try decoder.decode(Output.self, from: data)
    }

    func url(region: String) throws -> URL {
        guard let url = URL(
            string: "https://\(hostPrefix)rekognition.\(region).amazonaws.com\(requestURI)"
        ) else {
            throw PlaceholderError()
        }

        return url
    }
}

extension RekognitionAction where Input == RecognizeCelebritiesInput, Output == RecognizeCelebritiesOutputResponse {
    static func recognizeCelebrities(input: RecognizeCelebritiesInput) -> Self {
        .init(
            name: "RecognizeCelebrities",
            method: .post,
            requestURI: "/",
            successCode: 200,
            hostPrefix: "",
            xAmzTarget: "RekognitionService.RecognizeCelebrities",
            mapError: map(service: "Rekognition")
        )
    }
}

extension RekognitionAction where Input == SearchFacesByImageInput, Output == SearchFacesByImageOutputResponse {
    static func searchFacesByImage(input: SearchFacesByImageInput) -> Self {
        .init(
            name: "SearchFacesByImage",
            method: .post,
            requestURI: "/",
            successCode: 200,
            hostPrefix: "",
            xAmzTarget: "RekognitionService.SearchFacesByImage",
            mapError: map(service: "Rekognition")
        )
    }
}

extension RekognitionAction where Input == DetectFacesInput, Output == DetectFacesOutputResponse {
    static func detectFaces(input: DetectFacesInput) -> Self {
        .init(
            name: "DetectFaces",
            method: .post,
            requestURI: "/",
            successCode: 200,
            hostPrefix: "",
            xAmzTarget: "RekognitionService.DetectFaces",
            mapError: map(service: "Rekognition")
        )
    }
}


extension RekognitionAction where Input == DetectTextInput, Output == DetectTextOutputResponse {
    static func detectText(input: DetectTextInput) -> Self {
        .init(
            name: "DetectText",
            method: .post,
            requestURI: "/",
            successCode: 200,
            hostPrefix: "",
            xAmzTarget: "RekognitionService.DetectText",
            mapError: map(service: "Rekognition")
        )
    }
}


extension RekognitionAction where Input == DetectModerationLabelsInput, Output == DetectModerationLabelsOutputResponse {
    static func detectModerationLabels(input: DetectModerationLabelsInput) -> Self {
        .init(
            name: "DetectModerationLabels",
            method: .post,
            requestURI: "/",
            successCode: 200,
            hostPrefix: "",
            xAmzTarget: "RekognitionService.DetectModerationLabels",
            mapError: map(service: "Rekognition")
        )
    }
}


extension RekognitionAction where Input == DetectLabelsInput, Output == DetectLabelsOutputResponse {
    static func detectLabels(input: DetectLabelsInput) -> Self {
        .init(
            name: "DetectLabels",
            method: .post,
            requestURI: "/",
            successCode: 200,
            hostPrefix: "",
            xAmzTarget: "RekognitionService.DetectLabels",
            mapError: map(service: "Rekognition")
        )
    }
}
