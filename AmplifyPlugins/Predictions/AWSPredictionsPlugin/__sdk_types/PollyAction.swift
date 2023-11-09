//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import AWSPluginsCore

struct PollyAction<Input: Encodable, Output: Decodable> {
    let name: String
    let method: HTTPMethod
    let requestURI: String
    let successCode: Int
    let hostPrefix: String
    let mapError: (Data, HTTPURLResponse) throws -> Error

    let encode: (Input, JSONEncoder) throws -> Data = { model, encoder in
        try encoder.encode(model)
    }

    let decode: (Data, JSONDecoder) throws -> Output = { data, decoder in
        try decoder.decode(Output.self, from: data)
    }

    func url(region: String) throws -> URL {
        guard let url = URL(
            string: "https://\(hostPrefix)polly.\(region).amazonaws.com\(requestURI)"
        ) else {
            throw PlaceholderError()
        }

        return url
    }
}

extension PollyAction where Input == SynthesizeSpeechInput, Output == SynthesizeSpeechOutputResponse {

    static func synthesizeSpeech(input: SynthesizeSpeechInput) -> Self {
        .init(
            name: "SynthesizeSpeech",
            method: .post,
            requestURI: "/v1/speech",
            successCode: 200,
            hostPrefix: "",
            mapError: map(service: "Polly")
        )
    }
}


func map(service: String) -> ((Data, HTTPURLResponse) throws -> Error) {
    { data, response in
        ServiceError(
            message: String(decoding: data, as: UTF8.self),
            type: service,
            httpURLResponse: response
        )
    }
}
