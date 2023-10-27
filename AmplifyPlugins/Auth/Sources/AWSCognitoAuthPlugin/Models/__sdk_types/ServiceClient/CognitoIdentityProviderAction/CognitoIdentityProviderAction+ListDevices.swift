//
//  File.swift
//
//
//  Created by Saultz, Ian on 10/27/23.
//

import Foundation
import AWSPluginsCore

extension CognitoIdentityProviderAction where
Input == ListDevicesInput,
Output == ListDevicesOutputResponse {

    /*
     "ListDevices":{
       "name":"ListDevices",
       "http":{
         "method":"POST",
         "requestUri":"/"
       },
       "input":{"shape":"ListDevicesRequest"},
       "output":{"shape":"ListDevicesResponse"},
       "errors":[
         {"shape":"InvalidParameterException"},
         {"shape":"ResourceNotFoundException"},
         {"shape":"NotAuthorizedException"},
         {"shape":"InvalidUserPoolConfigurationException"},
         {"shape":"TooManyRequestsException"},
         {"shape":"PasswordResetRequiredException"},
         {"shape":"UserNotFoundException"},
         {"shape":"UserNotConfirmedException"},
         {"shape":"InternalErrorException"},
         {"shape":"ForbiddenException"}
       ],
       "authtype":"none"
     },
     */
    static func listDevices(region: String) -> Self {
        .init(
            name: "ListDevices",
            method: .post,
            xAmzTarget: "AWSCognitoIdentityProviderService.ListDevices",
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
