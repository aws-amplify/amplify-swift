//
//  File.swift
//
//
//  Created by Saultz, Ian on 10/27/23.
//

import Foundation
import AWSPluginsCore

extension CognitoIdentityProviderAction where
Input == ConfirmSignUpInput,
Output == ConfirmSignUpOutputResponse {

    /*
     "ConfirmSignUp":{
       "name":"ConfirmSignUp",
       "http":{
         "method":"POST",
         "requestUri":"/"
       },
       "input":{"shape":"ConfirmSignUpRequest"},
       "output":{"shape":"ConfirmSignUpResponse"},
       "errors":[
         {"shape":"ResourceNotFoundException"},
         {"shape":"InvalidParameterException"},
         {"shape":"UnexpectedLambdaException"},
         {"shape":"UserLambdaValidationException"},
         {"shape":"NotAuthorizedException"},
         {"shape":"TooManyFailedAttemptsException"},
         {"shape":"CodeMismatchException"},
         {"shape":"ExpiredCodeException"},
         {"shape":"InvalidLambdaResponseException"},
         {"shape":"AliasExistsException"},
         {"shape":"TooManyRequestsException"},
         {"shape":"LimitExceededException"},
         {"shape":"UserNotFoundException"},
         {"shape":"InternalErrorException"},
         {"shape":"ForbiddenException"}
       ],
       "authtype":"none"
     }
     */
    static func confirmSignUp(region: String) -> Self {
        .init(
            name: "ConfirmSignUp",
            method: .post,
            xAmzTarget: "AWSCognitoIdentityProviderService.ConfirmSignUp",
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
