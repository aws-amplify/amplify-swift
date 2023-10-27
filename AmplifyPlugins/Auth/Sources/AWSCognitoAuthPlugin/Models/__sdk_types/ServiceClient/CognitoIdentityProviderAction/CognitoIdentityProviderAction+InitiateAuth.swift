//
//  File.swift
//  
//
//  Created by Saultz, Ian on 10/27/23.
//

import Foundation
import AWSPluginsCore

extension CognitoIdentityProviderAction where
Input == InitiateAuthInput,
Output == InitiateAuthOutputResponse {

    /*
     "InitiateAuth":{
       "name":"InitiateAuth",
       "http":{
         "method":"POST",
         "requestUri":"/"
       },
       "input":{"shape":"InitiateAuthRequest"},
       "output":{"shape":"InitiateAuthResponse"},
       "errors":[
         {"shape":"ResourceNotFoundException"},
         {"shape":"InvalidParameterException"},
         {"shape":"NotAuthorizedException"},
         {"shape":"TooManyRequestsException"},
         {"shape":"UnexpectedLambdaException"},
         {"shape":"InvalidUserPoolConfigurationException"},
         {"shape":"UserLambdaValidationException"},
         {"shape":"InvalidLambdaResponseException"},
         {"shape":"PasswordResetRequiredException"},
         {"shape":"UserNotFoundException"},
         {"shape":"UserNotConfirmedException"},
         {"shape":"InternalErrorException"},
         {"shape":"InvalidSmsRoleAccessPolicyException"},
         {"shape":"InvalidSmsRoleTrustRelationshipException"},
         {"shape":"ForbiddenException"}
       ],
       "authtype":"none"
     },
     */
    static func initiateAuth(region: String) -> Self {
        .init(
            name: "GetId",
            method: .post,
            xAmzTarget: "AWSCognitoIdentityProviderService.InitiateAuth",
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
