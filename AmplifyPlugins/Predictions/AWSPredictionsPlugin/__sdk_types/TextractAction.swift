//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import AWSPluginsCore

struct TextractAction<Input: Encodable, Output: Decodable> {
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
            string: "https://\(hostPrefix)textract.\(region).amazonaws.com\(requestURI)"
        ) else {
            throw PlaceholderError()
        }

        return url
    }
}


// application/x-amz-json-1.1
extension TextractAction where Input == DetectDocumentTextInput, Output == DetectDocumentTextOutputResponse {
    static func detectDocumentText(input: DetectDocumentTextInput) -> Self {
        .init(
            name: "DetectDocumentText",
            method: .post,
            requestURI: "/",
            successCode: 200,
            hostPrefix: "",
            xAmzTarget: "Textract.DetectDocumentText",
            mapError: map(service: "textract")
        )
    }
}

extension TextractAction where Input == AnalyzeDocumentInput, Output == AnalyzeDocumentOutputResponse {
    static func analyzeDocument(input: AnalyzeDocumentInput) -> Self {
        .init(
            name: "AnalyzeDocument",
            method: .post,
            requestURI: "/",
            successCode: 200,
            hostPrefix: "",
            xAmzTarget: "Textract.AnalyzeDocument",
            mapError: map(service: "textract")
        )
    }
}
