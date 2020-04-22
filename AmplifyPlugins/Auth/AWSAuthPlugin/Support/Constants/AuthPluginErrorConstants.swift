//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify

typealias AuthPluginErrorString = (errorDescription: ErrorDescription, recoverySuggestion: RecoverySuggestion)

typealias AuthPluginValidationErrorString = (field: Field,
    errorDescription: ErrorDescription,
    recoverySuggestion: RecoverySuggestion)

struct AuthPluginErrorConstants {

    static let decodeConfigurationError: AuthPluginErrorString = (
        "Unable to decode configuration",
        "Make sure the plugin configuration is JSONValue")

    static let configurationObjectExpected: AuthPluginErrorString = (
        "Configuration was not a dictionary literal",
        "Make sure the value for the plugin is a dictionary literal")

    static let mobileClientInitializeError: AuthPluginErrorString = (
        "Unable to initialize the underlying AWSMobileClient",
        "Make sure that the necessary configuration are present in the configuration file")
}

// Field validation errors
extension AuthPluginErrorConstants {
    static let signInUsernameError: AuthPluginValidationErrorString = (
        "username",
        "Username is required to signIn",
        "Make sure that a valid username is passed during sigIn"
    )
}

// Recovery Messages
extension AuthPluginErrorConstants {
    static let userNotFoundError: RecoverySuggestion = "Make sure that the user is present in the backend"

    static let aliasExistsError: RecoverySuggestion = "Try with a different alias for the user"

    static let codeDeliveryError: RecoverySuggestion = "Make sure that the delivery destination is valid."

    static let codeMismatchError: RecoverySuggestion = "Retry with a valid code"

    static let codeExpiredError: RecoverySuggestion = "Rerun the flow to send the code again"

    static let lambdaError: RecoverySuggestion = "Make sure that the lambda configuration is correct"

    static let invalidParameterError: RecoverySuggestion = "Make sure that the parameters passed are valid"

    static let invalidPasswordError: RecoverySuggestion = "Make sure that the password is valid"

    static let mfaMethodNotFoundError: RecoverySuggestion = "Make sure that the user pool has a valid MFA configured"

    static let passwordResetRequired: RecoverySuggestion = "Reset the user password using the changePassword API"

    static let resourceNotFoundError: RecoverySuggestion = "Make sure that the user pool has a requested resource"

    static let softwareTokenNotFoundError: RecoverySuggestion = "Enable the software token MFA for the user"

    static let tooManyFailedError: RecoverySuggestion = "User might have tried too many times with failed input"

    static let tooManyRequestError: RecoverySuggestion = """
    Make sure the requests send are controlled and the errors are properlly handled
    """

    static let configurationError: RecoverySuggestion = """
    Make sure that the amplify configuration passed to Auth plugin is valid
    """

    static let userNotConfirmedError: RecoverySuggestion = "Confirm the user by calling confirmSignUp api"

    static let userNameExistsError: RecoverySuggestion = "Invoke the api with a different username"

    static let errorLoadingPageError: RecoverySuggestion = "Make sure that the UI is configured correctly"

    static let deviceNotRememberedError: RecoverySuggestion = "Call remeberDevice to track the device"

    static let invalidStateError: RecoverySuggestion = """
    Operation performed is not a valid operation for the current auth state
    """

    static let notAuthorizedError: RecoverySuggestion = """
    Check whether the given values are correct and the user is authorized to perform the operation.
    """

}
