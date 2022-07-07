//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify
import ClientRuntime
import AWSCognitoIdentityProvider

extension SignInError {

    var isUserUnConfirmed: Bool {
        switch self {
        case .service(error: let serviceError):
            if let cognitoError = serviceError as? SdkError<InitiateAuthOutputError>,
               case .service(let serviceError, _) = cognitoError,
               case .userNotConfirmedException = serviceError {
                return true
            } else if let cognitoError = serviceError as? SdkError<RespondToAuthChallengeOutputError>,
                      case .service(let serviceError, _) = cognitoError,
                      case .userNotConfirmedException = serviceError {
                return true
            } else if let cognitoError = serviceError as? InitiateAuthOutputError,
                       case .userNotConfirmedException = cognitoError {
                return true
            } else if let cognitoError = serviceError as? RespondToAuthChallengeOutputError,
                      case .userNotConfirmedException = cognitoError {
                return true
            }
            return false
        default:
            return false
        }
    }

    var isResetPassword: Bool {
        switch self {
        case .service(error: let serviceError):
            if let cognitoError = serviceError as? SdkError<InitiateAuthOutputError>,
               case .service(let serviceError, _) = cognitoError,
               case .passwordResetRequiredException = serviceError {
                return true
            } else if let cognitoError = serviceError as? SdkError<RespondToAuthChallengeOutputError>,
                      case .service(let serviceError, _) = cognitoError,
                      case .passwordResetRequiredException = serviceError {
                return true
            } else if let cognitoError = serviceError as? InitiateAuthOutputError,
                      case .passwordResetRequiredException = cognitoError {
                return true
            } else if let cognitoError = serviceError as? RespondToAuthChallengeOutputError,
                     case .passwordResetRequiredException = cognitoError {
                return true
            }
            return false
        default:
            return false
        }
    }
}

extension SignInError: AuthErrorConvertible {
    var authError: AuthError {
        switch self {
        case .configuration(let message):
            return AuthError.configuration(message, "")
        case .service(let error):
            if let initiateAuthError = error as? AuthErrorConvertible {
                return initiateAuthError.authError
            } else {
                return AuthError.unknown("", error)
            }
        case .invalidServiceResponse(message: let message):
            return AuthError.service(message, "")
        case .calculation:
            return AuthError.unknown("SignIn calculation returned an error")
        case .inputValidation(let field):
            return AuthError.validation(
                field,
                AuthPluginErrorConstants.signInUsernameError.errorDescription,
                AuthPluginErrorConstants.signInUsernameError.recoverySuggestion)
        case .unknown(let message):
            return .unknown(message, nil)
        case .hostedUI(let error):
            return error.authError
        }
    }
}

extension HostedUIError: AuthErrorConvertible {

    var authError: AuthError {
        switch self {
        case .signInURI:
            return .configuration("SignIn URI could not be created",
                                 "Check the configuration to make sure that HostedUI related information are present", nil)

        case .proofCalculation:
            return .invalidState("Proof calculation failed",
                                 "Try again after sometime", nil)

        case .codeValidation:
            return .validation("Code", "Code validation failed",
                               "Code returned by HostedUI could not be validated", nil)

        case .serviceMessage(let message):
            return .service(message, "Received an error message from service", nil)
        }
    }
}
