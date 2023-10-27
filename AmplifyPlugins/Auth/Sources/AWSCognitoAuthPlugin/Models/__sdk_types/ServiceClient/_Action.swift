//
//  File.swift
//  
//
//  Created by Saultz, Ian on 10/26/23.
//

import Foundation
import AWSPluginsCore

struct CognitoIdentityAction<Input: Encodable, Output: Decodable> {
    let name: String
    let method: HTTPMethod
    let xAmzTarget: String
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
            string: "https://\(hostPrefix)cognito-identity.\(region).amazonaws.com\(requestURI)"
        ) else {
            throw PlaceholderError()
        }

        return url
    }
}

extension CognitoIdentityAction {
    static func mapError(data: Data, response: HTTPURLResponse) throws -> Error {
        let error = try RestJSONError(data: data, response: response)
        switch error.type {
        case "ResourceConflictException": //
            return ResourceConflictException(
                name: error.type,
                message: error.message,
                httpURLResponse: response
            )
        case "InvalidParameterException": //
            return InvalidParameterException(
                name: error.type,
                message: error.message,
                httpURLResponse: response
            )
        case "NotAuthorizedException": //
            return NotAuthorizedException(
                name: error.type,
                message: error.message,
                httpURLResponse: response
            )
        case "ResourceNotFoundException": //
            return ResourceNotFoundException(
                name: error.type,
                message: error.message,
                httpURLResponse: response
            )
        case "InternalErrorException": //
            return InternalErrorException(
                name: error.type,
                message: error.message,
                httpURLResponse: response
            )
        case "ExternalServiceException": //
            return ExternalServiceException(
                name: error.type,
                message: error.message,
                httpURLResponse: response
            )
        case "InvalidIdentityPoolConfigurationException":
            return InvalidIdentityPoolConfigurationException(
                name: error.type,
                message: error.message,
                httpURLResponse: response
            )
        case "LimitExceededException": //
            return LimitExceededException(
                name: error.type,
                message: error.message,
                httpURLResponse: response
            )
        case "TooManyRequestsException": //
            return TooManyRequestsException(
                name: error.type,
                message: error.message,
                httpURLResponse: response
            )
        default:
            return ServiceError(
                message: error.message,
                type: error.type,
                httpURLResponse: response
            )
        }
    }
}

