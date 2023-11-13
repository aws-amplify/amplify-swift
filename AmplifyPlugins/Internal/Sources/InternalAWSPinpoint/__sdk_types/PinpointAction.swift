//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import AWSPluginsCore

struct PlaceholderError: Error {}

struct PinpointAction<Input: Encodable, Output: Decodable> {
    let name: String
    let method: HTTPMethod
    let requestURI: String
    let successCode: Int
    let hostPrefix: String
    let mapError: (Data, HTTPURLResponse) throws -> Error
    let encode: (Input, JSONEncoder) throws -> Data
    let decode: (Data, JSONDecoder) throws -> Output

    init(
        name: String,
        method: HTTPMethod,
        requestURI: String,
        successCode: Int,
        hostPrefix: String,
        mapError: @escaping (Data, HTTPURLResponse) -> Error,
        encode: @escaping (Input, JSONEncoder) throws -> Data = { model, encoder in
            try encoder.encode(model)
        },
        decode: @escaping (Data, JSONDecoder) throws -> Output = { data, decoder in
            try decoder.decode(Output.self, from: data)
        }
    ) {
        self.name = name
        self.method = method
        self.requestURI = requestURI
        self.successCode = successCode
        self.hostPrefix = hostPrefix
        self.mapError = mapError
        self.encode = encode
        self.decode = decode
    }

    func url(region: String) throws -> URL {
        guard let url = URL(
            string: "https://\(hostPrefix)pinpoint.\(region).amazonaws.com\(requestURI)"
        ) else {
            throw PlaceholderError()
        }

        return url
    }
}

extension PinpointAction where Input == UpdateEndpointInput, Output == UpdateEndpointOutputResponse {
    static func updateEndpoint(input: UpdateEndpointInput) -> Self {
        .init(
            name: "UpdateEndpoint",
            method: .put,
            requestURI: "/v1/apps/\(input.applicationId)/endpoints/\(input.endpointId)",
            successCode: 200,
            hostPrefix: "",
            mapError: { data, response in
                ServiceError(
                    message: String(decoding: data, as: UTF8.self),
                    type: "UpdateEndpoint",
                    httpURLResponse: response
                )
            },
            encode: { input, encoder in
                try encoder.encode(input.endpointRequest)
            },
            decode: { data, decoder in
                let body = try decoder.decode(
                    PinpointClientTypes.MessageBody.self,
                    from: data
                )
                return .init(messageBody: body)
            }
        )
    }
}

extension PinpointAction where Input == PutEventsInput, Output == PutEventsOutputResponse {
    static func putEvents(input: PutEventsInput) -> Self {
        .init(
            name: "PutEvents",
            method: .post,
            requestURI: "/v1/apps/\(input.applicationId)/events",
            successCode: 202,
            hostPrefix: "",
            mapError: { data, response in
                ServiceError(
                    message: String(decoding: data, as: UTF8.self),
                    type: "PutEvents",
                    httpURLResponse: response
                )
            },
            encode: { input, encoder in
                try encoder.encode(input.eventsRequest)
            },
            decode: { data, decoder in
                let body = try decoder.decode(
                    PinpointClientTypes.EventsResponse.self,
                    from: data
                )
                return .init(eventsResponse: body)
            }
        )
    }
}

extension PinpointAction where Input == DeleteUserEndpointsInput, Output == DeleteUserEndpointsOutputResponse {
    static func deleteUserEndpoints(input: DeleteUserEndpointsInput) -> Self {
        .init(
            name: "DeleteUserEndpoints",
            method: .delete,
            requestURI: "/v1/apps/\(input.applicationId)/users/\(input.userId)",
            successCode: 202,
            hostPrefix: "",
            mapError: { data, response in
                ServiceError(
                    message: String(decoding: data, as: UTF8.self),
                    type: "DeleteUserEndpoints",
                    httpURLResponse: response
                )
            },
            encode: { _, _ in .init() },
            decode: { data, decoder in
                let body = try decoder.decode(
                    PinpointClientTypes.EndpointsResponse.self,
                    from: data
                )
                return .init(endpointsResponse: body)
            }
        )
    }
}
