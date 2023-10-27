//
//  File.swift
//  
//
//  Created by Saultz, Ian on 10/27/23.
//

import Foundation
import AWSPluginsCore

struct CognitoIdentityProviderAction<Input: Encodable, Output: Decodable> {
    let name: String
    let method: HTTPMethod
    let xAmzTarget: String
    let requestURI: String
    let successCode: Int
    let hostPrefix: String
    let mapError: (Data, HTTPURLResponse) throws -> Error

    let encode: (Input, JSONEncoder) throws -> Data = { model, encoder in
        try encoder.encode(model)
    }

    var decode: (Data, JSONDecoder) throws -> Output = { data, decoder in
        try decoder.decode(Output.self, from: data)
    }

    func url(region: String) throws -> URL {
        guard let url = URL(
            string: "https://\(hostPrefix)cognito-idp.\(region).amazonaws.com\(requestURI)"
        ) else {
            throw PlaceholderError()
        }

        return url
    }
}

extension CognitoIdentityProviderAction {
    static func mapError(data: Data, response: HTTPURLResponse) throws -> Error {
        let error = try RestJSONError(data: data, response: response)
        switch error.type {
        case "ConcurrentModificationException":
            return ConcurrentModificationException(
                name: error.type,
                message: error.message,
                httpURLResponse: response
            )
        case "InvalidParameterException":
            return InvalidParameterException(
                name: error.type,
                message: error.message,
                httpURLResponse: response
            )
        case "NotAuthorizedException":
            return NotAuthorizedException(
                name: error.type,
                message: error.message,
                httpURLResponse: response
            )
        case "ResourceNotFoundException":
            return ResourceNotFoundException(
                name: error.type,
                message: error.message,
                httpURLResponse: response
            )
        case "InternalErrorException":
            return InternalErrorException(
                name: error.type,
                message: error.message,
                httpURLResponse: response
            )
        case "SoftwareTokenMFANotFoundException":
            return SoftwareTokenMFANotFoundException(
                name: error.type,
                message: error.message,
                httpURLResponse: response
            )
        case "ForbiddenException":
            return ForbiddenException(
                name: error.type,
                message: error.message,
                httpURLResponse: response
            )
        case "InvalidPasswordException":
            return InvalidPasswordException(
                name: error.type,
                message: error.message,
                httpURLResponse: response
            )
        case "LimitExceededException":
            return LimitExceededException(
                name: error.type,
                message: error.message,
                httpURLResponse: response
            )
        case "PasswordResetRequiredException":
            return PasswordResetRequiredException(
                name: error.type,
                message: error.message,
                httpURLResponse: response
            )
        case "TooManyRequestsException":
            return TooManyRequestsException(
                name: error.type,
                message: error.message,
                httpURLResponse: response
            )
        case "UserNotConfirmedException":
            return UserNotConfirmedException(
                name: error.type,
                message: error.message,
                httpURLResponse: response
            )
        case "CodeMismatchException":
            return CodeMismatchException(
                name: error.type,
                message: error.message,
                httpURLResponse: response
            )
        case "InvalidLambdaResponseException":
            return InvalidLambdaResponseException(
                name: error.type,
                message: error.message,
                httpURLResponse: response
            )
        case "ExpiredCodeException":
            return ExpiredCodeException(
                name: error.type,
                message: error.message,
                httpURLResponse: response
            )
        case "TooManyFailedAttemptsException":
            return TooManyFailedAttemptsException(
                name: error.type,
                message: error.message,
                httpURLResponse: response
            )
        case "UnexpectedLambdaException":
            return UnexpectedLambdaException(
                name: error.type,
                message: error.message,
                httpURLResponse: response
            )
        case "UserLambdaValidationException":
            return UserLambdaValidationException(
                name: error.type,
                message: error.message,
                httpURLResponse: response
            )
        case "InvalidUserPoolConfigurationException":
            return InvalidUserPoolConfigurationException(
                name: error.type,
                message: error.message,
                httpURLResponse: response
            )
        case "CodeDeliveryFailureException":
            return CodeDeliveryFailureException(
                name: error.type,
                message: error.message,
                httpURLResponse: response
            )
        case "InvalidEmailRoleAccessPolicyException":
            return InvalidEmailRoleAccessPolicyException(
                name: error.type,
                message: error.message,
                httpURLResponse: response
            )
        case "InvalidSmsRoleAccessPolicyException":
            return InvalidSmsRoleAccessPolicyException(
                name: error.type,
                message: error.message,
                httpURLResponse: response
            )
        case "InvalidSmsRoleTrustRelationshipException":
            return InvalidSmsRoleTrustRelationshipException(
                name: error.type,
                message: error.message,
                httpURLResponse: response
            )
        case "MFAMethodNotFoundException":
            return MFAMethodNotFoundException(
                name: error.type,
                message: error.message,
                httpURLResponse: response
            )
        case "UsernameExistsException":
            return UsernameExistsException(
                name: error.type,
                message: error.message,
                httpURLResponse: response
            )
        case "EnableSoftwareTokenMFAException":
            return EnableSoftwareTokenMFAException(
                name: error.type,
                message: error.message,
                httpURLResponse: response
            )
        case "AliasExistsException":
            return AliasExistsException(
                name: error.type,
                message: error.message,
                httpURLResponse: response
            )
        case "UserNotFoundException":
            return UserNotFoundException(
                name: error.type,
                message: error.message,
                httpURLResponse: response
            )
        default:
            return ServiceError(
                message: error.message,
                type: error.type,
                httpURLResponse: response
            )
        }
    }
}

