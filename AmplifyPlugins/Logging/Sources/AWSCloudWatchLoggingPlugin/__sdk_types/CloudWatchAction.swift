//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import AWSPluginsCore

struct PlaceholderError: Error {}

struct Action<Input: Encodable, Output: Decodable> {
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
            string: "https://\(hostPrefix)logs.\(region).amazonaws.com\(requestURI)"
        ) else {
            throw PlaceholderError()
        }

        return url
    }
}

extension Action where Input == DescribeLogStreamsInput, Output == DescribeLogStreamsOutputResponse {

    static func describeLogStreams(input: DescribeLogStreamsInput) -> Self {
        .init(
            name: "DescribeLogStreams",
            method: .post,
            requestURI: "/",
            successCode: 200,
            hostPrefix: "",
            xAmzTarget: "Logs_20140328.DescribeLogStreams",
            mapError: { data, response in
                ServiceError(
                    message: String(decoding: data, as: UTF8.self),
                    type: "DescribeLogStreams",
                    httpURLResponse: response
                )
            }
        )
    }
}

extension Action where Input == CreateLogStreamInput, Output == CreateLogStreamOutputResponse {

    static func createLogStream(input: CreateLogStreamInput) -> Self {
        .init(
            name: "CreateLogStream",
            method: .post,
            requestURI: "/",
            successCode: 200,
            hostPrefix: "",
            xAmzTarget: "Logs_20140328.CreateLogStream",
            mapError: { data, response in
                ServiceError(
                    message: String(decoding: data, as: UTF8.self),
                    type: "CreateLogStream",
                    httpURLResponse: response
                )
            }
        )
    }
}

extension Action where Input == PutLogEventsInput, Output == PutLogEventsOutputResponse {
    static func putLogEvents(input: PutLogEventsInput) -> Self {
        .init(
            name: "PutLogEvents",
            method: .post,
            requestURI: "/",
            successCode: 200,
            hostPrefix: "",
            xAmzTarget: "Logs_20140328.PutLogEvents",
            mapError: { data, response in
                ServiceError(
                    message: String(decoding: data, as: UTF8.self),
                    type: "PutLogEvents",
                    httpURLResponse: response
                )
            }
        )
    }
}

extension Action where Input == FilterLogEventsInput, Output == FilterLogEventsOutputResponse {
    static func filterLogEvents(input: FilterLogEventsInput) -> Self {
        .init(
            name: "FilterLogEvents",
            method: .post,
            requestURI: "/",
            successCode: 200,
            hostPrefix: "",
            xAmzTarget: "Logs_20140328.FilterLogEvents",
            mapError: { data, response in
                ServiceError(
                    message: String(decoding: data, as: UTF8.self),
                    type: "FilterLogEvents",
                    httpURLResponse: response
                )
            }
        )
    }
}

