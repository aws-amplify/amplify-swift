//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import AWSCognitoIdentity
import ClientRuntime
import Foundation

enum AuthorizationError: Error {
    case configuration(message: String)
    case service(error: Swift.Error)
    case invalidState(message: String)
    case invalidAWSCredentials(message: String)
    case invalidIdentityId(message: String)
    case invalidUserPoolTokens(message: String)
}

extension AuthorizationError: AuthErrorConvertible {
    var authError: AuthError {
        switch self {
        case .configuration(let message):
            return .configuration(message, "")
        case .service(let error):
            if let getIdOutputError = error as? SdkError<GetIdOutputError> {
                return getIdOutputError.authError
            } else if let getCredentialForIdentityError = error as? SdkError<GetCredentialsForIdentityOutputError> {
                return getCredentialForIdentityError.authError
            } else if let authError = error as? AuthError {
                return authError
            } else {
                return AuthError.unknown("", error)
            }
        case .invalidAWSCredentials(let message),
                .invalidIdentityId(let message),
                .invalidUserPoolTokens(let message):
            return .unknown(message, nil)
        case .invalidState(let message):
            return .invalidState(message, AuthPluginErrorConstants.invalidStateError, nil)
        }
    }
}

extension AuthorizationError: Equatable {
    static func == (lhs: AuthorizationError, rhs: AuthorizationError) -> Bool {
        switch (lhs, rhs) {
        case (.configuration(let lhsMessage), .configuration(let rhsMessage)):
            return lhsMessage == rhsMessage
        case (.service, .service):
            return true
        case (.invalidAWSCredentials, invalidAWSCredentials):
            return true
        case (.invalidIdentityId, invalidIdentityId):
            return true
        case (.invalidUserPoolTokens, .invalidUserPoolTokens):
            return true
        case (.invalidState, .invalidState):
            return true
        default:
            return false
        }
    }
}
