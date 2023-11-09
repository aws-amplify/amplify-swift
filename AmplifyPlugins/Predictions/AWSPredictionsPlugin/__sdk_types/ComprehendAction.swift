//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import AWSPluginsCore

struct PlaceholderError: Error {}

struct ComprehendAction<Input: Encodable, Output: Decodable> {
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
            string: "https://\(hostPrefix)comprehend.\(region).amazonaws.com\(requestURI)"
        ) else {
            throw PlaceholderError()
        }

        return url
    }
}

fileprivate func mapError(data: Data, response: HTTPURLResponse) throws -> Error {
    ServiceError(
        message: String(decoding: data, as: UTF8.self),
        type: "Comprehend",
        httpURLResponse: response
    )
}

extension ComprehendAction where Input == DetectDominantLanguageInput, Output == DetectDominantLanguageOutputResponse {
    static func detectDominantLanguage(input: DetectDominantLanguageInput) -> Self {
        .init(
            name: "DetectDominantLanguage",
            method: .post,
            requestURI: "/",
            successCode: 200,
            hostPrefix: "",
            xAmzTarget: "Comprehend_20171127.DetectDominantLanguage",
            mapError: mapError(data:response:)
        )
    }
}

// application/x-amz-json-1.1

extension ComprehendAction where Input == DetectSyntaxInput, Output == DetectSyntaxOutputResponse {
    static func detectSyntax(input: DetectSyntaxInput) -> Self {
        .init(
            name: "DetectSyntax",
            method: .post,
            requestURI: "/",
            successCode: 200,
            hostPrefix: "",
            xAmzTarget: "Comprehend_20171127.DetectSyntax",
            mapError: mapError(data:response:)
        )
    }
}

extension ComprehendAction where Input == DetectSentimentInput, Output == DetectSentimentOutputResponse {
    static func detectSentiment(input: DetectSentimentInput) -> Self {
        .init(
            name: "DetectSentiment",
            method: .post,
            requestURI: "/",
            successCode: 200,
            hostPrefix: "",
            xAmzTarget: "Comprehend_20171127.DetectSentiment",
            mapError: mapError(data:response:)
        )
    }
}

extension ComprehendAction where Input == DetectKeyPhrasesInput, Output == DetectKeyPhrasesOutputResponse {
    static func detectKeyPhrases(input: DetectKeyPhrasesInput) -> Self {
        .init(
            name: "DetectKeyPhrases",
            method: .post,
            requestURI: "/",
            successCode: 200,
            hostPrefix: "",
            xAmzTarget: "Comprehend_20171127.DetectKeyPhrases",
            mapError: mapError(data:response:)
        )
    }
}

extension ComprehendAction where Input == DetectEntitiesInput, Output == DetectEntitiesOutputResponse {
    static func detectEntities(input: DetectEntitiesInput) -> Self {
        .init(
            name: "DetectEntities",
            method: .post,
            requestURI: "/",
            successCode: 200,
            hostPrefix: "",
            xAmzTarget: "Comprehend_20171127.DetectEntities",
            mapError: mapError(data:response:)
        )
    }
}
