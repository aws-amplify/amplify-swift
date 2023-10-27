//
//  File.swift
//
//
//  Created by Saultz, Ian on 10/27/23.
//

import Foundation
import AWSPluginsCore

extension CognitoIdentityProviderAction where
Input == UpdateDeviceStatusInput,
Output == UpdateDeviceStatusOutputResponse {

    /*
     "UpdateDeviceStatus":{
       "name":"UpdateDeviceStatus",
       "http":{
         "method":"POST",
         "requestUri":"/"
       },
       "input":{"shape":"UpdateDeviceStatusRequest"},
       "output":{"shape":"UpdateDeviceStatusResponse"},
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
    static func updateDeviceStatus(region: String) -> Self {
        .init(
            name: "UpdateDeviceStatus",
            method: .post,
            xAmzTarget: "AWSCognitoIdentityProviderService.UpdateDeviceStatus",
            requestURI: "/",
            successCode: 200,
            hostPrefix: "",
            mapError: mapError(data:response:)
        )
    }
}
