//
//  File.swift
//
//
//  Created by Saultz, Ian on 10/27/23.
//

import Foundation
import AWSPluginsCore

extension CognitoIdentityProviderAction where
Input == GetUserAttributeVerificationCodeInput,
Output == GetUserAttributeVerificationCodeOutputResponse {

    /*
     "GetUserAttributeVerificationCode":{
           "name":"GetUserAttributeVerificationCode",
           "http":{
             "method":"POST",
             "requestUri":"/"
           },
           "input":{"shape":"GetUserAttributeVerificationCodeRequest"},
           "output":{"shape":"GetUserAttributeVerificationCodeResponse"},
           "errors":[
             {"shape":"ResourceNotFoundException"},
             {"shape":"InvalidParameterException"},
             {"shape":"TooManyRequestsException"},
             {"shape":"NotAuthorizedException"},
             {"shape":"UnexpectedLambdaException"},
             {"shape":"UserLambdaValidationException"},
             {"shape":"InvalidLambdaResponseException"},
             {"shape":"InvalidSmsRoleAccessPolicyException"},
             {"shape":"InvalidSmsRoleTrustRelationshipException"},
             {"shape":"InvalidEmailRoleAccessPolicyException"},
             {"shape":"CodeDeliveryFailureException"},
             {"shape":"LimitExceededException"},
             {"shape":"PasswordResetRequiredException"},
             {"shape":"UserNotFoundException"},
             {"shape":"UserNotConfirmedException"},
             {"shape":"InternalErrorException"},
             {"shape":"ForbiddenException"}
           ],
           "authtype":"none"
         },
     */
    static func getUserAttributeVerificationCode(region: String) -> Self {
        .init(
            name: "GetUserAttributeVerificationCode",
            method: .post,
            xAmzTarget: "AWSCognitoIdentityProviderService.GetUserAttributeVerificationCode",
            requestURI: "/",
            successCode: 200,
            hostPrefix: "",
            mapError: mapError(data:response:)
        )
    }
}
