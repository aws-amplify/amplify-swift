//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Foundation

extension WebAuthnError: AuthErrorConvertible {
    var authError: AuthError {
        switch self {
        case .userCancelled:
            return .service(
                AuthPluginErrorConstants.signInWithWebAuthnUserCancelledError.errorDescription,
                AuthPluginErrorConstants.signInWithWebAuthnUserCancelledError.recoverySuggestion,
                self
            )
        case .assertionFailed(error: let error):
            return .service(
                AuthPluginErrorConstants.signInWithWebAuthnAssertionFailedError.errorDescription,
                AuthPluginErrorConstants.signInWithWebAuthnAssertionFailedError.recoverySuggestion,
                error
            )
        case .creationFailed(error: let error):
            return .service(
                AuthPluginErrorConstants.associateWebAuthnCreationFailedError.errorDescription,
                AuthPluginErrorConstants.associateWebAuthnCreationFailedError.recoverySuggestion,
                error
            )
        case .credentialAlreadyExist:
            return .service(
                AuthPluginErrorConstants.associateWebAuthnCredentialAlreadyExistError.errorDescription,
                AuthPluginErrorConstants.associateWebAuthnCredentialAlreadyExistError.recoverySuggestion,
                self
            )
        case .service(let error):
            // TODO: Map the SDK errors
            return .service(
                "Something went wrong",
                "Try Again later",
                error
            )
        case .unknown(let message, let error):
            return .unknown(message, error)
        }
    }
}
