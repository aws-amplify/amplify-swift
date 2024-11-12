//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import AuthenticationServices
import Foundation

extension WebAuthnError: AuthErrorConvertible {
    var authError: AuthError {
        switch self {
        case .assertionFailed(error: let error):
            let errorString: AuthPluginErrorString
            if error.code == .canceled {
                errorString = AuthPluginErrorConstants.signInWithWebAuthnUserCancelledError
            } else {
                errorString = AuthPluginErrorConstants.signInWithWebAuthnAssertionFailedError
            }

            return .service(
                errorString.errorDescription,
                errorString.recoverySuggestion,
                error
            )
        case .creationFailed(error: let error):
            let errorString: AuthPluginErrorString
            if case .canceled = error.code {
                errorString = AuthPluginErrorConstants.associateWebAuthnCredentialUserCancelledError
            } else if isMatchedExcludedCredential(error.code) {
                errorString = AuthPluginErrorConstants.associateWebAuthnCredentialAlreadyExistError
            } else {
                errorString = AuthPluginErrorConstants.associateWebAuthnCreationFailedError
            }

            return .service(
                errorString.errorDescription,
                errorString.recoverySuggestion,
                error
            )
        case .service(let error):
            return error.authError
        case .unknown(let message, let error):
            return .service(
                "An unknown error type was thrown by the service. \(message).",
                """
                This should not happen. There is a possibility that there is a bug if this error persists.
                Please take a look at https://github.com/aws-amplify/amplify-swift/issues to see if there are any
                existing issues that match your scenario, and file an issue with the details of the bug if there isn't.
                """,
                error
            )
        }
    }

    private func isMatchedExcludedCredential(_ code: ASAuthorizationError.Code) -> Bool {
        // ASAuthorizationError.matchedExcludedCredential is only defined in iOS 18/macOS 15,
        // This check doesn't work correctly without these runtimes installed.
        // Until we require Xcode 16, we'll just use its rawValue
        // if #available(iOS 18.0, macOS 15.0, *) {
        //     return code == .matchedExcludedCredential
        // } else {
        //     return code.rawValue == 1006
        // }
        return code.rawValue == 1006
    }
}
