//
//  File.swift
//
//
//  Created by Saultz, Ian on 10/27/23.
//

import Foundation
import AWSPluginsCore

extension CognitoIdentityProviderAction where
Input == ChangePasswordInput,
Output == ChangePasswordOutputResponse {

    /*
     "ChangePassword":{
       "name":"ChangePassword",
       "http":{
         "method":"POST",
         "requestUri":"/"
       },
       "input":{"shape":"ChangePasswordRequest"},
       "output":{"shape":"ChangePasswordResponse"},
       "errors":[
         {"shape":"ResourceNotFoundException"},
         {"shape":"InvalidParameterException"},
         {"shape":"InvalidPasswordException"},
         {"shape":"NotAuthorizedException"},
         {"shape":"TooManyRequestsException"},
         {"shape":"LimitExceededException"},
         {"shape":"PasswordResetRequiredException"},
         {"shape":"UserNotFoundException"},
         {"shape":"UserNotConfirmedException"},
         {"shape":"InternalErrorException"},
         {"shape":"ForbiddenException"}
       ],
       "authtype":"none"
     },
     */
    static func changePassword(region: String) -> Self {
        .init(
            name: "ChangePassword",
            method: .post,
            xAmzTarget: "AWSCognitoIdentityProviderService.ChangePassword",
            requestURI: "/",
            successCode: 200,
            hostPrefix: "",
            mapError: mapError(data:response:)
        )
    }
}
