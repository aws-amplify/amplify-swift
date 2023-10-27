//
//  File.swift
//
//
//  Created by Saultz, Ian on 10/27/23.
//

import Foundation
import AWSPluginsCore

extension CognitoIdentityProviderAction where
Input == VerifySoftwareTokenInput,
Output == VerifySoftwareTokenOutputResponse {

    /*
     "VerifySoftwareToken":{
       "name":"VerifySoftwareToken",
       "http":{
         "method":"POST",
         "requestUri":"/"
       },
       "input":{"shape":"VerifySoftwareTokenRequest"},
       "output":{"shape":"VerifySoftwareTokenResponse"},
       "errors":[
         {"shape":"InvalidParameterException"},
         {"shape":"ResourceNotFoundException"},
         {"shape":"InvalidUserPoolConfigurationException"},
         {"shape":"NotAuthorizedException"},
         {"shape":"TooManyRequestsException"},
         {"shape":"PasswordResetRequiredException"},
         {"shape":"UserNotFoundException"},
         {"shape":"UserNotConfirmedException"},
         {"shape":"InternalErrorException"},
         {"shape":"EnableSoftwareTokenMFAException"},
         {"shape":"NotAuthorizedException"},
         {"shape":"SoftwareTokenMFANotFoundException"},
         {"shape":"CodeMismatchException"},
         {"shape":"ForbiddenException"}
       ],
       "authtype":"none"
     },
     */
    static func verifySoftwareToken(region: String) -> Self {
        .init(
            name: "VerifySoftwareToken",
            method: .post,
            xAmzTarget: "AWSCognitoIdentityProviderService.VerifySoftwareToken",
            requestURI: "/",
            successCode: 200,
            hostPrefix: "",
            mapError: mapError(data:response:)
        )
    }
}
