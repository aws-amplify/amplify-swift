//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify

typealias AuthPluginErrorString = (errorDescription: ErrorDescription, recoverySuggestion: RecoverySuggestion)

typealias AuthPluginValidationErrorString = (field: Field,
    errorDescription: ErrorDescription,
    recoverySuggestion: RecoverySuggestion)

enum AuthPluginErrorConstants {

    static let decodeConfigurationError: AuthPluginErrorString = (
        "Unable to decode configuration",
        "Make sure the plugin configuration is JSONValue")

    static let configurationObjectExpected: AuthPluginErrorString = (
        "Configuration was not a dictionary literal",
        "Make sure the value for the plugin is a dictionary literal")

    static let hostedUISecurityFailedError: AuthPluginErrorString = (
        "Found invalid parameter while parsing the webUI redirect URL",
        "Make sure that the signIn URL has not been modified during the signIn flow")

    static let hostedUIUserCancelledError: AuthPluginErrorString = (
        "User cancelled the signIn flow and could not be completed.",
        "Present the signIn UI again for the user to sign in.")

    static let hostedUIUserCancelledSignOutError: AuthPluginErrorString = (
        "User cancelled the signOut flow and could not be completed.",
        "Present the signOut UI again for the user to sign out.")

    static let userInvalidError: AuthPluginErrorString = (
        "Could not validate the user",
        "Get the current user Auth.getCurrentUser() and make the request")
    static let identityIdSignOutError: AuthPluginErrorString = (
        "There is no user signed in to retreive identity id",
        "Call Auth.signIn to sign in a user or enable unauthenticated access in AWS Cognito Identity Pool")

    static let awsCredentialsSignOutError: AuthPluginErrorString = (
        "There is no user signed in to retreive AWS credentials",
        "Call Auth.signIn to sign in a user or enable unauthenticated access in AWS Cognito Identity Pool")

    static let cognitoTokensSignOutError: AuthPluginErrorString = (
        "There is no user signed in to retreive cognito tokens",
        "Call Auth.signIn to sign in a user and then call Auth.fetchSession")

    static let userSubSignOutError: AuthPluginErrorString = (
        "There is no user signed in to retreive user sub",
        "Call Auth.signIn to sign in a user and then call Auth.fetchSession")

    static let identityIdOfflineError: AuthPluginErrorString = (
        "A network error occured while trying to fetch identity id",
        "Try again with exponential backoff")

    static let awsCredentialsOfflineError: AuthPluginErrorString = (
        "A network error occured while trying to fetch AWS credentials",
        "Try again with exponential backoff")

    static let usersubOfflineError: AuthPluginErrorString = (
        "A network error occured while trying to fetch user sub",
        "Try again with exponential backoff")

    static let cognitoTokenOfflineError: AuthPluginErrorString = (
        "A network error occured while trying to fetch AWS Cognito Tokens",
        "Try again with exponential backoff")

    static let identityIdServiceError: AuthPluginErrorString = (
        "A serivce error occured while trying to fetch identity id",
        "Try again with exponential backoff")

    static let awsCredentialsServiceError: AuthPluginErrorString = (
        "A service error occured while trying to fetch AWS credentials",
        "Try again with exponential backoff")

    static let identityIdSessionExpiredError: AuthPluginErrorString = (
        "Session expired could not fetch identity id",
        "Invoke Auth.signIn to re-authenticate the user")

    static let awsCredentialsSessionExpiredError: AuthPluginErrorString = (
        "Session expired could not fetch AWS Credentials",
        "Invoke Auth.signIn to re-authenticate the user")

    static let usersubSessionExpiredError: AuthPluginErrorString = (
        "Session expired could not fetch user sub",
        "Invoke Auth.signIn to re-authenticate the user")

    static let cognitoTokensSessionExpiredError: AuthPluginErrorString = (
        "Session expired could not fetch cognito tokens",
        "Invoke Auth.signIn to re-authenticate the user")

    static let cognitoTokenSignedInThroughCIDPError: AuthPluginErrorString = (
        "User is not signed in through Cognito User pool",
        "Tokens are not valid with user signed in through AWS Cognito Identity Pool")

    static let userSubSignedInThroughCIDPError: AuthPluginErrorString = (
        "User is not signed in through Cognito User pool",
        "User sub are not valid with user signed in through AWS Cognito Identity Pool")

    static let signedInIdentityIdWithNoCIDPError: AuthPluginErrorString = (
        "Could not fetch identity Id, AWS Cognito Identity Pool is not configured",
        "Follow the steps to configure AWS Cognito Identity Pool and try again")

    static let signedInAWSCredentialsWithNoCIDPError: AuthPluginErrorString = (
        "Could not fetch AWS Credentials, AWS Cognito Identity Pool is not configured",
        "Follow the steps to configure AWS Cognito Identity Pool and try again")

    static let fetchAttributeSignedOutError: AuthPluginErrorString = (
    "Could not fetch attributes, there is no user signed in to the Auth category",
    "SignIn to Auth category by using one of the sign in methods and then call user attributes apis")

    static let updateAttributeSignedOutError: AuthPluginErrorString = (
    "Could not update attributes, there is no user signed in to the Auth category",
    "SignIn to Auth category by using one of the sign in methods and then call user attributes apis")

    static let resendAttributeCodeSignedOutError: AuthPluginErrorString = (
    "Could not resend attribute confirmation code, there is no user signed in to the Auth category",
    "SignIn to Auth category by using one of the sign in methods and then call user attributes apis")

    static let confirmAttributeSignedOutError: AuthPluginErrorString = (
    "Could not confirm attribute, there is no user signed in to the Auth category",
    "SignIn to Auth category by using one of the sign in methods and then call user attributes apis")

    static let changePasswordSignedOutError: AuthPluginErrorString = (
    "Could not change password, there is no user signed in to the Auth category",
    "Change password require a user signed in to Auth category, use one of the signIn apis to signIn")

    static let changePasswordUnableToSignInError: AuthPluginErrorString = (
    "Could not change password, the user session is expired",
    "Re-authenticate the user by using one of the signIn apis")

    static let userSignedOutError: AuthPluginErrorString = (
    "There is no user signed in to the Auth category",
    "SignIn to Auth category by using one of the sign in methods and then try again")
}

// Field validation errors
extension AuthPluginErrorConstants {
    static let signInUsernameError: AuthPluginValidationErrorString = (
        "username",
        "Username is required to signIn",
        "Make sure that a valid username is passed during sigIn"
    )

    static let signUpUsernameError: AuthPluginValidationErrorString = (
        "username",
        "Username is required to signUp",
        "Make sure that a valid username is passed for signUp"
    )

    static let signUpPasswordError: AuthPluginValidationErrorString = (
        "password",
        "Password is required to signUp",
        "Make sure that a valid password is passed for signUp"
    )

    static let confirmSignUpUsernameError: AuthPluginValidationErrorString = (
        "username",
        "Username is required to confirmSignUp",
        "Make sure that a valid username is passed for confirmSignUp"
    )

    static let resendSignUpCodeUsernameError: AuthPluginValidationErrorString = (
        "username",
        "Username is required to confirmSignUp",
        "Make sure that a valid username is passed for confirmSignUp"
    )

    static let confirmSignUpCodeError: AuthPluginValidationErrorString = (
        "code",
        "code is required to confirmSignUp",
        "Make sure that a valid code is passed for confirmSignUp"
    )

    static let confirmSignInChallengeResponseError: AuthPluginValidationErrorString = (
        "challengeResponse",
        "challengeResponse is required to confirmSignIn",
        "Make sure that a valid challenge response is passed for confirmSignIn"
    )

    static let confirmResetPasswordUsernameError: AuthPluginValidationErrorString = (
        "username",
        "username is required to confirmResetPassword",
        "Make sure that a valid username is passed for confirmResetPassword"
    )

    static let confirmResetPasswordNewPasswordError: AuthPluginValidationErrorString = (
        "newPassword",
        "newPassword is required to confirmResetPassword",
        "Make sure that a valid newPassword is passed for confirmResetPassword"
    )

    static let confirmResetPasswordCodeError: AuthPluginValidationErrorString = (
        "confirmationCode",
        "confirmationCode is required to confirmResetPassword",
        "Make sure that a valid confirmationCode is passed for confirmResetPassword"
    )

    static let resetPasswordUsernameError: AuthPluginValidationErrorString = (
        "username",
        "username is required to resetPassword",
        "Make sure that a valid username is passed for resetPassword"
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
    Make sure the requests send are controlled and the errors are properly handled
    """

    static let limitExceededError: RecoverySuggestion = """
    Make sure that the request made to the particular AWS resources are under the resource quota limits
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

    static let hostedUIBadRequestError: RecoverySuggestion = "Retry the webUi signIn"

    static let configurationMissingError: RecoverySuggestion = """
    Could not read Cognito Service configuration from the auth configuration. Make sure that auth category
    is properly configured and auth information are present in the configuration. You can use Amplify CLI to
    configure the auth category.
    """

    static let externalServiceException: RecoverySuggestion = """
    An exception thrown when a dependent service such as Facebook or Twitter is not responding
    """

    static let limitExceededException: RecoverySuggestion = """
    The total number of user pools has exceeded a preset limit.
    """

    static let resourceConflictException: RecoverySuggestion = """
    Check if the login is already linked to another account.
    """

    static let invalidEmailRoleError: RecoverySuggestion = """
    Check the email identity used with Cognito Service
    """

    static let invalidSMSRoleError: RecoverySuggestion = """
    Check the role provided for SMS configuration in Cognito Service
    """

}
