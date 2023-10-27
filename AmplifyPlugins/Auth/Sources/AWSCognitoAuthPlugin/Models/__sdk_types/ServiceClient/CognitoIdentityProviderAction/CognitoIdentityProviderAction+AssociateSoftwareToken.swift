//
//  File.swift
//
//
//  Created by Saultz, Ian on 10/27/23.
//

import Foundation
import AWSPluginsCore

extension CognitoIdentityProviderAction where
Input == AssociateSoftwareTokenInput,
Output == AssociateSoftwareTokenOutputResponse {

    /*
     "AssociateSoftwareToken":{
     "name":"AssociateSoftwareToken",
     "http":{
     "method":"POST",
     "requestUri":"/"
     },
     "input":{"shape":"AssociateSoftwareTokenRequest"},
     "output":{"shape":"AssociateSoftwareTokenResponse"},
     "errors":[
     {"shape":"ConcurrentModificationException"},
     {"shape":"InvalidParameterException"},
     {"shape":"NotAuthorizedException"},
     {"shape":"ResourceNotFoundException"},
     {"shape":"InternalErrorException"},
     {"shape":"SoftwareTokenMFANotFoundException"},
     {"shape":"ForbiddenException"}
     ],
     "authtype":"none"
     },
     */
    static func associateSoftwareToken(region: String) -> Self {
        .init(
            name: "AssociateSoftwareToken",
            method: .post,
            xAmzTarget: "AWSCognitoIdentityProviderService.AssociateSoftwareToken",
            requestURI: "/",
            successCode: 200,
            hostPrefix: "",
            mapError: mapError(data:response:)
        )
    }
}
