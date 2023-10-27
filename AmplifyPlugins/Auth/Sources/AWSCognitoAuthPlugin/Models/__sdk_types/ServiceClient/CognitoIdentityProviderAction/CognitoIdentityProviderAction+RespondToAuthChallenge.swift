//
//  File.swift
//  
//
//  Created by Saultz, Ian on 10/27/23.
//

import Foundation
import AWSPluginsCore

extension CognitoIdentityProviderAction where
Input == RespondToAuthChallengeInput,
Output == RespondToAuthChallengeOutputResponse {

    /*
     "RespondToAuthChallenge":{
       "name":"RespondToAuthChallenge",
       "http":{
         "method":"POST",
         "requestUri":"/"
       },
       "input":{"shape":"RespondToAuthChallengeRequest"},
       "output":{"shape":"RespondToAuthChallengeResponse"},
       "errors":[
         {"shape":"ResourceNotFoundException"},
         {"shape":"InvalidParameterException"},
         {"shape":"NotAuthorizedException"},
         {"shape":"CodeMismatchException"},
         {"shape":"ExpiredCodeException"},
         {"shape":"UnexpectedLambdaException"},
         {"shape":"UserLambdaValidationException"},
         {"shape":"InvalidPasswordException"},
         {"shape":"InvalidLambdaResponseException"},
         {"shape":"TooManyRequestsException"},
         {"shape":"InvalidUserPoolConfigurationException"},
         {"shape":"MFAMethodNotFoundException"},
         {"shape":"PasswordResetRequiredException"},
         {"shape":"UserNotFoundException"},
         {"shape":"UserNotConfirmedException"},
         {"shape":"InvalidSmsRoleAccessPolicyException"},
         {"shape":"InvalidSmsRoleTrustRelationshipException"},
         {"shape":"AliasExistsException"},
         {"shape":"InternalErrorException"},
         {"shape":"SoftwareTokenMFANotFoundException"},
         {"shape":"ForbiddenException"}
       ],
       "authtype":"none"
     }
     */
    static func respondToAuthChallenge(region: String) -> Self {
        .init(
            name: "RespondToAuthChallenge",
            method: .post,
            xAmzTarget: "AWSCognitoIdentityProviderService.RespondToAuthChallenge",
            requestURI: "/",
            successCode: 200,
            hostPrefix: "",
            mapError: mapError(data:response:)
        )
    }
}
