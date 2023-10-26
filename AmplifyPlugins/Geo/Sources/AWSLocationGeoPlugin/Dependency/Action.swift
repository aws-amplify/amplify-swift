//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import AWSPluginsCore

struct Action<Input: Encodable, Output: Decodable> {
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
            string: "https://\(hostPrefix)geo.\(region).amazonaws.com\(requestURI)"
        ) else {
            throw PlaceholderError()
        }

        return url
    }
}

extension Action where Input == SearchPlaceIndexForTextInput, Output == SearchPlaceIndexForTextOutputResponse {
    /*
    "SearchPlaceIndexForText":{
       "name":"SearchPlaceIndexForText",
       "http":{
         "method":"POST",
         "requestUri":"/places/v0/indexes/{IndexName}/search/text",
         "responseCode":200
       },
       "input":{"shape":"SearchPlaceIndexForTextRequest"},
       "output":{"shape":"SearchPlaceIndexForTextResponse"},
       "errors":[
         {"shape":"InternalServerException"},
         {"shape":"ResourceNotFoundException"},
         {"shape":"AccessDeniedException"},
         {"shape":"ValidationException"},
         {"shape":"ThrottlingException"}
       ],
       "endpoint":{"hostPrefix":"places."}
     }
     */
    static func searchPlaceIndexForText(indexName: String) -> Self {
        .init(
            name: "SearchPlaceIndexForText",
            method: .post,
            requestURI: "/places/v0/indexes/\(indexName)/search/text",
            successCode: 200,
            hostPrefix: "places.",
            mapError: { data, response in
                let error = try RestJSONError(data: data, response: response)
                switch error.type {
                case "AccessDeniedException":
                    return ServiceError(message: error.message, type: error.type, httpURLResponse: response)
                case "InternalServerException":
                    return ServiceError(message: error.message, type: error.type, httpURLResponse: response)
                case "ResourceNotFoundException":
                    return ServiceError(message: error.message, type: error.type, httpURLResponse: response)
                case "ThrottlingException":
                    return ServiceError(message: error.message, type: error.type, httpURLResponse: response)
                case "ValidationException":
                    return ServiceError(message: error.message, type: error.type, httpURLResponse: response)
                default:
                    return ServiceError(message: error.message, type: error.type, httpURLResponse: response)
                }
            }
        )
    }
}

extension Action where Input == SearchPlaceIndexForPositionInput, Output == SearchPlaceIndexForPositionOutputResponse {

    /*
     "SearchPlaceIndexForPosition":{
       "name":"SearchPlaceIndexForPosition",
       "http":{
         "method":"POST",
         "requestUri":"/places/v0/indexes/{IndexName}/search/position",
         "responseCode":200
       },
       "input":{"shape":"SearchPlaceIndexForPositionRequest"},
       "output":{"shape":"SearchPlaceIndexForPositionResponse"},
       "errors":[
         {"shape":"InternalServerException"},
         {"shape":"ResourceNotFoundException"},
         {"shape":"AccessDeniedException"},
         {"shape":"ValidationException"},
         {"shape":"ThrottlingException"}
       ],
       "endpoint":{"hostPrefix":"places."}
     }
     */
    static func searchPlaceIndexForPosition(indexName: String) -> Self {
        .init(
            name: "SearchPlaceIndexForPosition",
            method: .post,
            requestURI: "/places/v0/indexes/\(indexName)/search/position",
            successCode: 200,
            hostPrefix: "places.",
            mapError: { data, response in
                let error = try RestJSONError(data: data, response: response)
                switch error.type {
                case "AccessDeniedException":
                    return ServiceError(message: error.message, type: error.type, httpURLResponse: response)
                case "InternalServerException":
                    return ServiceError(message: error.message, type: error.type, httpURLResponse: response)
                case "ResourceNotFoundException":
                    return ServiceError(message: error.message, type: error.type, httpURLResponse: response)
                case "ThrottlingException":
                    return ServiceError(message: error.message, type: error.type, httpURLResponse: response)
                case "ValidationException":
                    return ServiceError(message: error.message, type: error.type, httpURLResponse: response)
                default:
                    return ServiceError(message: error.message, type: error.type, httpURLResponse: response)
                }
            }
        )
    }
}
