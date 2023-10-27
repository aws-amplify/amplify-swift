//
//  File.swift
//
//
//  Created by Saultz, Ian on 10/27/23.
//

import Foundation
import AWSPluginsCore

extension CognitoIdentityProviderAction where
Input == DeleteUserInput,
Output == DeleteUserOutputResponse {

    /*
     "DeleteUser":{
       "name":"DeleteUser",
       "http":{
         "method":"POST",
         "requestUri":"/"
       },
       "input":{"shape":"DeleteUserRequest"},
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
    static func deleteUser(region: String) -> Self {
        .init(
            name: "DeleteUser",
            method: .post,
            xAmzTarget: "AWSCognitoIdentityProviderService.DeleteUser",
            requestURI: "/",
            successCode: 200,
            hostPrefix: "",
            mapError: mapError(data:response:)
        )
    }
}
