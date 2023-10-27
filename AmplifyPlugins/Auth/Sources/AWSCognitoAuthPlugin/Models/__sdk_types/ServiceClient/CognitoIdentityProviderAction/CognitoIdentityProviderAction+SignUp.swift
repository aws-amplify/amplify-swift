//
//  File.swift
//  
//
//  Created by Saultz, Ian on 10/27/23.
//

import Foundation
import AWSPluginsCore

extension CognitoIdentityProviderAction where
Input == SignUpInput,
Output == SignUpOutputResponse {

    /*
     "SignUp":{
       "name":"SignUp",
       "http":{
         "method":"POST",
         "requestUri":"/"
       },
       "input":{"shape":"SignUpRequest"},
       "output":{"shape":"SignUpResponse"},
       "errors":[
         {"shape":"ResourceNotFoundException"},
         {"shape":"InvalidParameterException"},
         {"shape":"UnexpectedLambdaException"},
         {"shape":"UserLambdaValidationException"},
         {"shape":"NotAuthorizedException"},
         {"shape":"InvalidPasswordException"},
         {"shape":"InvalidLambdaResponseException"},
         {"shape":"UsernameExistsException"},
         {"shape":"TooManyRequestsException"},
         {"shape":"InternalErrorException"},
         {"shape":"InvalidSmsRoleAccessPolicyException"},
         {"shape":"InvalidSmsRoleTrustRelationshipException"},
         {"shape":"InvalidEmailRoleAccessPolicyException"},
         {"shape":"CodeDeliveryFailureException"},
         {"shape":"ForbiddenException"}
       ],
       "authtype":"none"
     },
     */
    static func signUp(region: String) -> Self {
        .init(
            name: "SignUp",
            method: .post,
            xAmzTarget: "AWSCognitoIdentityProviderService.SignUp",
            requestURI: "/",
            successCode: 200,
            hostPrefix: "",
            mapError: mapError(data:response:)
        )
    }
}
