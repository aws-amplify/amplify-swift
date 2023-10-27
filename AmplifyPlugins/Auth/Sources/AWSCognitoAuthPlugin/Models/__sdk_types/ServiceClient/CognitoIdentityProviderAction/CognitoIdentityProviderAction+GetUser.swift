//
//  File.swift
//
//
//  Created by Saultz, Ian on 10/27/23.
//

import Foundation
import AWSPluginsCore

extension CognitoIdentityProviderAction where
Input == GetUserInput,
Output == GetUserOutputResponse {

    /*
     "GetUser":{
       "name":"GetUser",
       "http":{
         "method":"POST",
         "requestUri":"/"
       },
       "input":{"shape":"GetUserRequest"},
       "output":{"shape":"GetUserResponse"},
       "errors":[
         {"shape":"ResourceNotFoundException"},
         {"shape":"InvalidParameterException"},
         {"shape":"NotAuthorizedException"},
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
    static func getUser(region: String) -> Self {
        .init(
            name: "GetUser",
            method: .post,
            xAmzTarget: "AWSCognitoIdentityProviderService.GetUser",
            requestURI: "/",
            successCode: 200,
            hostPrefix: "",
            mapError: mapError(data:response:)
        )
    }
}
