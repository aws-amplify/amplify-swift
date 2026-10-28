//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AuthenticationServices
import Foundation

package enum WebAuthnError: Error {
    case assertionFailed(error: ASAuthorizationError)
    case creationFailed(error: ASAuthorizationError)
    case service(error: EngineAuthErrorConvertible)
    case unknown(message: String, error: Error? = nil)
}

package extension WebAuthnError {

    /// A passkey sign-in step's service failure: the engine error, and the error it was made from (`cause`, the SDK's
    /// exception), for a caller that maps the failure itself: the engine error keeps nothing under an
    /// `InternalErrorException`.
    ///
    /// It describes, debug-describes and reflects as its engine error, so a state that holds it (the plugin logs every
    /// state at verbose, "Auth state change") prints as it did when the step kept only the engine error.
    struct ServiceFailure: Error, EngineAuthErrorConvertible, CustomStringConvertible,
        CustomDebugStringConvertible, CustomReflectable {
        package let engineError: EngineAuthError
        package let cause: Error

        package init(_ error: EngineAuthErrorConvertible & Error) {
            self.engineError = error.engineError
            self.cause = error
        }

        package var description: String {
            String(describing: engineError)
        }

        package var debugDescription: String {
            String(reflecting: engineError)
        }

        package var customMirror: Mirror {
            Mirror(reflecting: engineError)
        }
    }
}

extension WebAuthnError: Equatable {
    package static func == (lhs: WebAuthnError, rhs: WebAuthnError) -> Bool {
        switch (lhs, rhs) {
        case (.assertionFailed(let lError), .assertionFailed(let rError)):
            return lError == rError
        case (.creationFailed(let lError), .creationFailed(let rError)):
            return lError == rError
        case (.service(let lhsError), .service(let rhsError)):
            return areEquals(lhsError.engineError, rhsError.engineError)
        case (.unknown(let lhsMessage, let lhsError), .unknown(let rhsMessage, let rhsError)):
            return lhsMessage == rhsMessage && areEquals(lhsError, rhsError)
        default:
            return false
        }
    }

    private static func areEquals(_ lhsError: Error?, _ rhsError: Error?) -> Bool {
        guard let lhsError, let rhsError else {
            return false
        }
        let left = lhsError as NSError
        let right = rhsError as NSError
        return left.code == right.code &&
            left.domain == right.domain
    }
}
