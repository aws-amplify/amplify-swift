//
//  File.swift
//
//
//  Created by Saultz, Ian on 10/27/23.
//

import Foundation
import AWSPluginsCore

extension CognitoIdentityProviderAction where
Input == UpdateUserAttributesInput,
Output == UpdateUserAttributesOutputResponse {

    /*
     "UpdateUserAttributes":{
       "name":"UpdateUserAttributes",
       "http":{
         "method":"POST",
         "requestUri":"/"
       },
       "input":{"shape":"UpdateUserAttributesRequest"},
       "output":{"shape":"UpdateUserAttributesResponse"},
       "errors":[
         {"shape":"ResourceNotFoundException"},
         {"shape":"InvalidParameterException"},
         {"shape":"CodeMismatchException"},
         {"shape":"ExpiredCodeException"},
         {"shape":"NotAuthorizedException"},
         {"shape":"UnexpectedLambdaException"},
         {"shape":"UserLambdaValidationException"},
         {"shape":"InvalidLambdaResponseException"},
         {"shape":"TooManyRequestsException"},
         {"shape":"AliasExistsException"},
         {"shape":"InvalidSmsRoleAccessPolicyException"},
         {"shape":"InvalidSmsRoleTrustRelationshipException"},
         {"shape":"InvalidEmailRoleAccessPolicyException"},
         {"shape":"CodeDeliveryFailureException"},
         {"shape":"PasswordResetRequiredException"},
         {"shape":"UserNotFoundException"},
         {"shape":"UserNotConfirmedException"},
         {"shape":"InternalErrorException"},
         {"shape":"ForbiddenException"}
       ],
       "authtype":"none"
     },
     */
    static func updateUserAttributes(region: String) -> Self {
        .init(
            name: "UpdateUserAttributes",
            method: .post,
            xAmzTarget: "AWSCognitoIdentityProviderService.UpdateUserAttributes",
            requestURI: "/",
            successCode: 200,
            hostPrefix: "",
            mapError: mapError(data:response:)
        )
    }
}
