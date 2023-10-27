//
//  File.swift
//
//
//  Created by Saultz, Ian on 10/27/23.
//

import Foundation
import AWSPluginsCore

extension CognitoIdentityProviderAction where
Input == AssociateSoftwareTokenInput,
Output == AssociateSoftwareTokenOutputResponse {

    /*
     "AssociateSoftwareToken":{
       "name":"AssociateSoftwareToken",
       "http":{
         "method":"POST",
         "requestUri":"/"
       },
       "input":{"shape":"AssociateSoftwareTokenRequest"},
       "output":{"shape":"AssociateSoftwareTokenResponse"},
       "errors":[
         {"shape":"ConcurrentModificationException"},
         {"shape":"InvalidParameterException"},
         {"shape":"NotAuthorizedException"},
         {"shape":"ResourceNotFoundException"},
         {"shape":"InternalErrorException"},
         {"shape":"SoftwareTokenMFANotFoundException"},
         {"shape":"ForbiddenException"}
       ],
       "authtype":"none"
     },
     */
    static func associateSoftwareToken(region: String) -> Self {
        .init(
            name: "AssociateSoftwareToken",
            method: .post,
            xAmzTarget: "AWSCognitoIdentityProviderService.AssociateSoftwareToken",
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
