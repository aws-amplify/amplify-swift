//
//  File.swift
//
//
//  Created by Saultz, Ian on 10/27/23.
//

import Foundation
import AWSPluginsCore

extension CognitoIdentityProviderAction where
Input == ForgetDeviceInput,
Output == ForgetDeviceOutputResponse {

    /*
     "ForgetDevice":{
       "name":"ForgetDevice",
       "http":{
         "method":"POST",
         "requestUri":"/"
       },
       "input":{"shape":"ForgetDeviceRequest"},
       "errors":[
         {"shape":"ResourceNotFoundException"},
         {"shape":"InvalidParameterException"},
         {"shape":"NotAuthorizedException"},
         {"shape":"TooManyRequestsException"},
         {"shape":"InvalidUserPoolConfigurationException"},
         {"shape":"PasswordResetRequiredException"},
         {"shape":"UserNotFoundException"},
         {"shape":"UserNotConfirmedException"},
         {"shape":"InternalErrorException"},
         {"shape":"ForbiddenException"}
       ],
       "authtype":"none"
     },
     */
    static func forgetDevice(region: String) -> Self {
        .init(
            name: "ForgetDevice",
            method: .post,
            xAmzTarget: "AWSCognitoIdentityProviderService.ForgetDevice",
            requestURI: "/",
            successCode: 200,
            hostPrefix: "",
            mapError: mapError(data:response:)
        )
    }
}
