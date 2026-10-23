//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AWSCognitoIdentity
import ClientRuntime
import Foundation
import AmplifyFoundation

package enum AuthorizationError: Error {
    case configuration(message: String)
    case service(error: Swift.Error)
    case invalidState(message: String)
    case sessionError(FetchSessionError, AmplifyCredentials)
    case sessionExpired(error: Error)
}

extension AuthorizationError: EngineAuthErrorConvertible {
    package var engineError: EngineAuthError {
        switch self {
        case .sessionExpired(let error):
            return .sessionExpired(
                "Session expired",
                "Invoke Auth.signIn to re-authenticate the user",
                error
            )
        case .configuration(let message):
            return .configuration(message, "")
        case .service(let error):
            if let convertibleError = error as? EngineAuthErrorConvertible {
                return convertibleError.engineError
            } else {
                return .service(
                    "Service error occurred",
                    EngineErrorMessages.reportBugToAWS(function: Self.reportBugFunction),
                    error
                )
            }
        case .invalidState(let message):
            return .invalidState(message, AuthPluginErrorConstants.invalidStateError, nil)
        case .sessionError(let sessionError, _):
            return sessionError.engineError
        }
    }

    /// The `function:` that `reportBugToAWS()` has always embedded here: the text was originally built in
    /// `var authError`. Kept so the recovery text is unchanged.
    private static let reportBugFunction: StaticString = "authError"

}

extension AuthorizationError: Equatable {
    package static func == (lhs: AuthorizationError, rhs: AuthorizationError) -> Bool {
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
