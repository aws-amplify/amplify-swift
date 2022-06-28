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
    case sessionError(FetchSessionError, AmplifyCredentials)
    case sessionExpired
}

extension AuthorizationError: AuthErrorConvertible {
    var authError: AuthError {
        switch self {
        case .sessionExpired:
            return .sessionExpired("", "", nil)
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
        case .invalidState(let message):
            return .invalidState(message, AuthPluginErrorConstants.invalidStateError, nil)
        case .sessionError(_, _):
            return .invalidState("Session in error", AuthPluginErrorConstants.invalidStateError, nil)
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
        case (.invalidState, .invalidState):
            return true
        case (.sessionExpired, .sessionExpired):
            return true
        case (.sessionError(let lhsError, _), .sessionError(let rhsError, _)):
            return lhsError == rhsError
        default:
            return false
        }
    }
}
