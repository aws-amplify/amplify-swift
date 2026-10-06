//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

extension SignUpError: EngineAuthErrorConvertible {
    package var engineError: EngineAuthError {
        switch self {
        case .invalidState(message: let message):
            fatalError("Fix me \(message)")
        case .invalidUsername:
            return EngineAuthError.validation(
                AuthPluginErrorConstants.signUpUsernameError.field,
                AuthPluginErrorConstants.signUpUsernameError.errorDescription,
                AuthPluginErrorConstants.signUpUsernameError.recoverySuggestion, nil
            )
        case .invalidPassword:
            return EngineAuthError.validation(
                AuthPluginErrorConstants.signUpPasswordError.field,
                AuthPluginErrorConstants.signUpPasswordError.errorDescription,
                AuthPluginErrorConstants.signUpPasswordError.recoverySuggestion, nil
            )
        case .invalidConfirmationCode(message: let message):
            fatalError("Fix me \(message)")
        case .service(error: let error):
            if let initiateAuthError = error as? EngineAuthErrorConvertible {
                return initiateAuthError.engineError
            } else {
                return EngineAuthError.unknown("Received unknown error from service", error)
            }
        }
    }
}
