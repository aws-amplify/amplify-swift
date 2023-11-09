//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import AWSPluginsCore

struct TranslateAction<Input: Encodable, Output: Decodable> {
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
            string: "https://\(hostPrefix)translate.\(region).amazonaws.com\(requestURI)"
        ) else {
            throw PlaceholderError()
        }

        return url
    }
}

// application/x-amz-json-1.1

extension TranslateAction where Input == TranslateTextInput, Output == TranslateTextOutputResponse {

    static func translateText(input: TranslateTextInput) -> Self {
        .init(
            name: "TranslateText",
            method: .post,
            requestURI: "/",
            successCode: 200,
            hostPrefix: "",
            xAmzTarget: "AWSShineFrontendService_20170701.TranslateText",
            mapError: map(service: "translate")
        )
    }
}
