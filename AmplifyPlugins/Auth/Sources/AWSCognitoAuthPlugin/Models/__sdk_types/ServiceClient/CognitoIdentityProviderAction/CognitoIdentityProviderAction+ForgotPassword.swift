//
//  File.swift
//
//
//  Created by Saultz, Ian on 10/27/23.
//

import Foundation
import AWSPluginsCore

extension CognitoIdentityProviderAction where
Input == ForgotPasswordInput,
Output == ForgotPasswordOutputResponse {

    /*
     "ForgotPassword":{
       "name":"ForgotPassword",
       "http":{
         "method":"POST",
         "requestUri":"/"
       },
       "input":{"shape":"ForgotPasswordRequest"},
       "output":{"shape":"ForgotPasswordResponse"},
       "errors":[
         {"shape":"ResourceNotFoundException"},
         {"shape":"InvalidParameterException"},
         {"shape":"UnexpectedLambdaException"},
         {"shape":"UserLambdaValidationException"},
         {"shape":"NotAuthorizedException"},
         {"shape":"InvalidLambdaResponseException"},
         {"shape":"TooManyRequestsException"},
         {"shape":"LimitExceededException"},
         {"shape":"InvalidSmsRoleAccessPolicyException"},
         {"shape":"InvalidSmsRoleTrustRelationshipException"},
         {"shape":"InvalidEmailRoleAccessPolicyException"},
         {"shape":"CodeDeliveryFailureException"},
         {"shape":"UserNotFoundException"},
         {"shape":"InternalErrorException"},
         {"shape":"ForbiddenException"}
       ],
       "authtype":"none"
     },
     */
    static func forgotPassword(region: String) -> Self {
        .init(
            name: "ForgotPassword",
            method: .post,
            xAmzTarget: "AWSCognitoIdentityProviderService.ForgotPassword",
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
