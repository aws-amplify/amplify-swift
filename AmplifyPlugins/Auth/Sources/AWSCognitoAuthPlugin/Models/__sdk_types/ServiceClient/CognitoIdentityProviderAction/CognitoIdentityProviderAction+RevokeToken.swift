//
//  File.swift
//
//
//  Created by Saultz, Ian on 10/27/23.
//

import Foundation
import AWSPluginsCore

extension CognitoIdentityProviderAction where
Input == RevokeTokenInput,
Output == RevokeTokenOutputResponse {

    /*
     "RevokeToken":{
       "name":"RevokeToken",
       "http":{
         "method":"POST",
         "requestUri":"/"
       },
       "input":{"shape":"RevokeTokenRequest"},
       "output":{"shape":"RevokeTokenResponse"},
       "errors":[
         {"shape":"TooManyRequestsException"},
         {"shape":"InternalErrorException"},
         {"shape":"UnauthorizedException"},
         {"shape":"InvalidParameterException"},
         {"shape":"UnsupportedOperationException"},
         {"shape":"UnsupportedTokenTypeException"},
         {"shape":"ForbiddenException"}
       ],
       "authtype":"none"
     },
     */
    static func revokeToken(region: String) -> Self {
        .init(
            name: "RevokeToken",
            method: .post,
            xAmzTarget: "AWSCognitoIdentityProviderService.RevokeToken",
            requestURI: "/",
            successCode: 200,
            hostPrefix: "",
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
