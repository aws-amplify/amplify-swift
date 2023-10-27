//
//  File.swift
//
//
//  Created by Saultz, Ian on 10/27/23.
//

import Foundation
import AWSPluginsCore

extension CognitoIdentityProviderAction where
Input == GlobalSignOutInput,
Output == GlobalSignOutOutputResponse {

    /*
     "GlobalSignOut":{
       "name":"GlobalSignOut",
       "http":{
         "method":"POST",
         "requestUri":"/"
       },
       "input":{"shape":"GlobalSignOutRequest"},
       "output":{"shape":"GlobalSignOutResponse"},
       "errors":[
         {"shape":"ResourceNotFoundException"},
         {"shape":"InvalidParameterException"},
         {"shape":"NotAuthorizedException"},
         {"shape":"TooManyRequestsException"},
         {"shape":"PasswordResetRequiredException"},
         {"shape":"UserNotConfirmedException"},
         {"shape":"InternalErrorException"},
         {"shape":"ForbiddenException"}
       ],
       "authtype":"none"
     },
     */
    static func globalSignOut(region: String) -> Self {
        .init(
            name: "GlobalSignOut",
            method: .post,
            xAmzTarget: "AWSCognitoIdentityProviderService.GlobalSignOut",
            requestURI: "/",
            successCode: 200,
            hostPrefix: "",
            mapError: mapError(data:response:)
        )
    }
}
