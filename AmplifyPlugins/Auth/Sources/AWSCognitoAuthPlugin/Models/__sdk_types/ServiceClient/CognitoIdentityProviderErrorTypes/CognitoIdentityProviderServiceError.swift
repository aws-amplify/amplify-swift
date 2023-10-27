//
//  File.swift
//  
//
//  Created by Saultz, Ian on 10/27/23.
//

import Foundation

struct ConcurrentModificationException: Error {
    let name: String?
    let message: String?
    let httpURLResponse: HTTPURLResponse
}

struct InvalidParameterException: Error {
    let name: String?
    let message: String?
    let httpURLResponse: HTTPURLResponse
}

struct NotAuthorizedException: Error {
    let name: String?
    let message: String?
    let httpURLResponse: HTTPURLResponse
}

struct ResourceNotFoundException: Error {
    let name: String?
    let message: String?
    let httpURLResponse: HTTPURLResponse
}

struct InternalErrorException: Error {
    let name: String?
    let message: String?
    let httpURLResponse: HTTPURLResponse
}

struct SoftwareTokenMFANotFoundException: Error {
    let name: String?
    let message: String?
    let httpURLResponse: HTTPURLResponse
}

struct ForbiddenException: Error {
    let name: String?
    let message: String?
    let httpURLResponse: HTTPURLResponse
}

struct InvalidPasswordException: Error {
    let name: String?
    let message: String?
    let httpURLResponse: HTTPURLResponse
}

struct LimitExceededException: Error {
    let name: String?
    let message: String?
    let httpURLResponse: HTTPURLResponse
}

struct PasswordResetRequiredException: Error {
    let name: String?
    let message: String?
    let httpURLResponse: HTTPURLResponse
}

struct TooManyRequestsException: Error {
    let name: String?
    let message: String?
    let httpURLResponse: HTTPURLResponse
}

struct UserNotConfirmedException: Error {
    let name: String?
    let message: String?
    let httpURLResponse: HTTPURLResponse
}

struct CodeMismatchException: Error {
    let name: String?
    let message: String?
    let httpURLResponse: HTTPURLResponse
}

struct InvalidLambdaResponseException: Error {
    let name: String?
    let message: String?
    let httpURLResponse: HTTPURLResponse
}

struct ExpiredCodeException: Error {
    let name: String?
    let message: String?
    let httpURLResponse: HTTPURLResponse
}

struct TooManyFailedAttemptsException: Error {
    let name: String?
    let message: String?
    let httpURLResponse: HTTPURLResponse
}

struct UnexpectedLambdaException: Error {
    let name: String?
    let message: String?
    let httpURLResponse: HTTPURLResponse
}

struct UserLambdaValidationException: Error {
    let name: String?
    let message: String?
    let httpURLResponse: HTTPURLResponse
}

struct InvalidUserPoolConfigurationException: Error {
    let name: String?
    let message: String?
    let httpURLResponse: HTTPURLResponse
}

struct CodeDeliveryFailureException: Error {
    let name: String?
    let message: String?
    let httpURLResponse: HTTPURLResponse
}

struct InvalidEmailRoleAccessPolicyException: Error {
    let name: String?
    let message: String?
    let httpURLResponse: HTTPURLResponse
}

struct InvalidSmsRoleAccessPolicyException: Error {
    let name: String?
    let message: String?
    let httpURLResponse: HTTPURLResponse
}

struct InvalidSmsRoleTrustRelationshipException: Error {
    let name: String?
    let message: String?
    let httpURLResponse: HTTPURLResponse
}

struct MFAMethodNotFoundException: Error {
    let name: String?
    let message: String?
    let httpURLResponse: HTTPURLResponse
}

struct UsernameExistsException: Error {
    let name: String?
    let message: String?
    let httpURLResponse: HTTPURLResponse
}

struct EnableSoftwareTokenMFAException: Error {
    let name: String?
    let message: String?
    let httpURLResponse: HTTPURLResponse
}

struct AliasExistsException: Error {
    let name: String?
    let message: String?
    let httpURLResponse: HTTPURLResponse
}

struct UserNotFoundException: Error {
    let name: String?
    let message: String?
    let httpURLResponse: HTTPURLResponse
}

// Cognito Identity

struct ResourceConflictException: Error {
    let name: String?
    let message: String?
    let httpURLResponse: HTTPURLResponse
}

struct ExternalServiceException: Error {
    let name: String?
    let message: String?
    let httpURLResponse: HTTPURLResponse
}

struct InvalidIdentityPoolConfigurationException: Error {
    let name: String?
    let message: String?
    let httpURLResponse: HTTPURLResponse
}
