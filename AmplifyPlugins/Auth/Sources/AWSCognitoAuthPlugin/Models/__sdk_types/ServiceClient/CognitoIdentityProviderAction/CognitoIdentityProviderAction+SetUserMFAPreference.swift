//
//  File.swift
//
//
//  Created by Saultz, Ian on 10/27/23.
//

import Foundation
import AWSPluginsCore

extension CognitoIdentityProviderAction where
Input == SetUserMFAPreferenceInput,
Output == SetUserMFAPreferenceOutputResponse {

    /*
     "SetUserMFAPreference":{
       "name":"SetUserMFAPreference",
       "http":{
         "method":"POST",
         "requestUri":"/"
       },
       "input":{"shape":"SetUserMFAPreferenceRequest"},
       "output":{"shape":"SetUserMFAPreferenceResponse"},
       "errors":[
         {"shape":"ResourceNotFoundException"},
         {"shape":"InvalidParameterException"},
         {"shape":"NotAuthorizedException"},
         {"shape":"PasswordResetRequiredException"},
         {"shape":"UserNotFoundException"},
         {"shape":"UserNotConfirmedException"},
         {"shape":"InternalErrorException"},
         {"shape":"ForbiddenException"}
       ],
       "authtype":"none"
     },
     */
    static func setUserMFAPreference(region: String) -> Self {
        .init(
            name: "SetUserMFAPreference",
            method: .post,
            xAmzTarget: "AWSCognitoIdentityProviderService.SetUserMFAPreference",
            requestURI: "/",
            successCode: 200,
            hostPrefix: "",
            mapError: mapError(data:response:)
        )
    }
}
