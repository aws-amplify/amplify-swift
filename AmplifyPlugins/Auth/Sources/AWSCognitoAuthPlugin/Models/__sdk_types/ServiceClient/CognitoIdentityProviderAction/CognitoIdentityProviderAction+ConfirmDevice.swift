//
//  File.swift
//
//
//  Created by Saultz, Ian on 10/27/23.
//

import Foundation
import AWSPluginsCore

extension CognitoIdentityProviderAction where
Input == ConfirmDeviceInput,
Output == ConfirmDeviceOutputResponse {

    /*
     "ConfirmDevice":{
       "name":"ConfirmDevice",
       "http":{
         "method":"POST",
         "requestUri":"/"
       },
       "input":{"shape":"ConfirmDeviceRequest"},
       "output":{"shape":"ConfirmDeviceResponse"},
       "errors":[
         {"shape":"ResourceNotFoundException"},
         {"shape":"InvalidParameterException"},
         {"shape":"NotAuthorizedException"},
         {"shape":"InvalidPasswordException"},
         {"shape":"InvalidLambdaResponseException"},
         {"shape":"UsernameExistsException"},
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
    static func confirmDevice(region: String) -> Self {
        .init(
            name: "ConfirmDevice",
            method: .post,
            xAmzTarget: "AWSCognitoIdentityProviderService.ConfirmDevice",
            requestURI: "/",
            successCode: 200,
            hostPrefix: "",
            mapError: mapError(data:response:)
        )
    }
}
