//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AWSCognitoIdentityProvider
import ClientRuntime

protocol CognitoUserPoolBehavior {

    /// Throws InitiateAuthOutputError
    func initiateAuth(input: InitiateAuthInput) async throws -> InitiateAuthOutput

    /// Throws RespondToAuthChallengeOutputError
    func respondToAuthChallenge(
        input: RespondToAuthChallengeInput) async throws -> RespondToAuthChallengeOutput

    /// Throws SignUpOutputError
    func signUp(input: SignUpInput) async throws -> SignUpOutput

    /// Throws ConfirmSignUpOutputError
    func confirmSignUp(input: ConfirmSignUpInput) async throws -> ConfirmSignUpOutput

    /// Throws GlobalSignOutOutputError
    func globalSignOut(input: GlobalSignOutInput) async throws -> GlobalSignOutOutput

    /// Throws RevokeTokenOutputError
    func revokeToken(input: RevokeTokenInput) async throws -> RevokeTokenOutput

    // MARK: - User Attribute API's

    /// Throws GetUserAttributeVerificationCodeOutputError
    func getUserAttributeVerificationCode(input: GetUserAttributeVerificationCodeInput) async throws -> GetUserAttributeVerificationCodeOutput

    /// Throws GetUserOutputError
    func getUser(input: GetUserInput) async throws -> GetUserOutput

    /// Throws UpdateUserAttributesOutputError
    func updateUserAttributes(input: UpdateUserAttributesInput) async throws -> UpdateUserAttributesOutput

    /// Verifies the specified user attributes in the user pool.
    /// Throws VerifyUserAttributeOutputError
    func verifyUserAttribute(input: AWSCognitoIdentityProvider.VerifyUserAttributeInput) async throws -> AWSCognitoIdentityProvider.VerifyUserAttributeOutput

    /// Changes the password for a specified user in a user pool.
    /// Throws ChangePasswordOutputError
    func changePassword(input: ChangePasswordInput) async throws -> ChangePasswordOutput

    /// Delete the signed in user from the user pool.
    /// Throws DeleteUserOutputError
    func deleteUser(input: DeleteUserInput) async throws -> DeleteUserOutput

    /// Resends sign up code
    /// Throws ResendConfirmationCodeOutputError
    func resendConfirmationCode(input: ResendConfirmationCodeInput) async throws -> ResendConfirmationCodeOutput

    /// Resets password
    /// Throws ForgotPasswordOutputError
    func forgotPassword(input: ForgotPasswordInput) async throws -> ForgotPasswordOutput

    /// Confirm Reset password
    /// Throws ConfirmForgotPasswordOutputError
    func confirmForgotPassword(input: ConfirmForgotPasswordInput) async throws -> ConfirmForgotPasswordOutput

    /// Lists the devices
    func listDevices(input: ListDevicesInput) async throws -> ListDevicesOutput

    /// Updates the device status
    func updateDeviceStatus(input: UpdateDeviceStatusInput) async throws -> UpdateDeviceStatusOutput

    /// Forgets the specified device.
    func forgetDevice(input: ForgetDeviceInput) async throws -> ForgetDeviceOutput

    /// Confirms tracking of the device. This API call is the call that begins device tracking.
    /// Throws ConfirmDeviceOutputError
    func confirmDevice(input: ConfirmDeviceInput) async throws -> ConfirmDeviceOutput

    /// Creates a new request to associate a new software token for the user
    /// Throws AssociateSoftwareTokenOutputError
    func associateSoftwareToken(input: AssociateSoftwareTokenInput) async throws -> AssociateSoftwareTokenOutput

    /// Register a user's entered time-based one-time password (TOTP) code and mark the user's software token MFA status as "verified" if successful.
    /// Throws VerifySoftwareTokenOutputError
    func verifySoftwareToken(input: VerifySoftwareTokenInput) async throws -> VerifySoftwareTokenOutput

    /// Set the user's multi-factor authentication (MFA) method preference, including which MFA factors are activated and if any are preferred.
    /// Throws SetUserMFAPreferenceOutputError
    func setUserMFAPreference(input: SetUserMFAPreferenceInput) async throws -> SetUserMFAPreferenceOutput

    /// Lists the WebAuthn credentials
    ///
    /// - Parameter input: A `ListWebAuthnCredentialsInput` that contains the access token
    /// - Returns: a `ListWebAuthnCredentialsOutput` that contains the list of WebAuthn credentials
    /// - Throws: See  __Possible Errors__ bellow.
    ///
    /// __Possible Errors:__
    /// - `ForbiddenException` :  WAF rejected the request based on a web ACL associated with the user pool.
    /// - `InternalErrorException` : Amazon Cognito encountered an internal error.
    /// - `InvalidParameterException` : Amazon Cognito encountered an invalid parameter.
    /// - `NotAuthorizedException` :  The user isn't authorized.
    func listWebAuthnCredentials(input: ListWebAuthnCredentialsInput) async throws -> ListWebAuthnCredentialsOutput

    /// Deletes a WebAuthn credential.
    ///
    /// - Parameter input: A `DeleteWebAuthnCredentialInput` that contains the access token and the ID of the credential to delete
    /// - Returns: An empty `DeleteWebAuthnCredentialOutput`.
    /// - Throws: See  __Possible Errors__ bellow.
    ///
    /// __Possible Errors:__
    /// - `ForbiddenException` :  WAF rejected the request based on a web ACL associated with the user pool.
    /// - `InternalErrorException` : Amazon Cognito encountered an internal error.
    /// - `InvalidParameterException` : Amazon Cognito encountered an invalid parameter.
    /// - `NotAuthorizedException` :  The user isn't authorized.
    /// - `ResourceNotFoundException` : The Amazon Cognito service couldn't find the requested resource.
    func deleteWebAuthnCredential(input: DeleteWebAuthnCredentialInput) async throws -> DeleteWebAuthnCredentialOutput


    /// Starts the registration of a new WebAuthn credential
    ///
    /// - Parameter input: A `GetWebAuthnRegistrationOptionsInput` that contains the access token
    /// - Returns: A `GetWebAuthnRegistrationOptionsOutput` that contains the credential creation options
    /// - Throws: See  __Possible Errors__ bellow.
    ///
    /// __Possible Errors:__
    /// - `ForbiddenException` :  WAF rejected the request based on a web ACL associated with the user pool.
    /// - `InternalErrorException` : Amazon Cognito encountered an internal error.
    /// - `InvalidParameterException` : Amazon Cognito encountered an invalid parameter.
    /// - `LimitExceededException` : The user has exceeded the limit for a this resource.
    /// - `NotAuthorizedException` :  The user isn't authorized.
    /// - `TooManyRequestsException` : The user has made too many requests for this operation
    /// - `WebAuthnConfigurationMissingException` : The user presented passkey credentials from an unregistered device.
    /// - `WebAuthnNotEnabledException` : The user selected passkey authentication but it's not enabled.
    func startWebAuthnRegistration(input: StartWebAuthnRegistrationInput) async throws -> StartWebAuthnRegistrationOutput

    /// Completes the registration of a WebAuthn credential.
    ///
    /// - Parameter input: A `VerifyWebAuthnRegistrationResultInput` that contains the access token and the credential to verify
    /// - Returns: An empty `VerifyWebAuthnRegistrationResultOutput`
    /// - Throws: See  __Possible Errors__ bellow.
    ///
    /// __Possible Errors:__
    /// - `ForbiddenException` :  WAF rejected the request based on a web ACL associated with the user pool.
    /// - `InternalErrorException` : Amazon Cognito encountered an internal error.
    /// - `InvalidParameterException` : Amazon Cognito encountered an invalid parameter.
    /// - `NotAuthorizedException` :  The user isn't authorized.
    /// - `TooManyRequestsException` : The user has made too many requests for this operation.
    /// - `WebAuthnChallengeNotFoundException` : Passkey credentials were sent to a challenge that doesn't match an existing request.
    /// - `WebAuthnClientMismatchException` : The user attempted to sign in with a passkey with an app client that doesn't support passkey authentication.
    /// - `WebAuthnCredentialNotSupportedException` : The user presented passkey credentials from an unsupported device.
    /// - `WebAuthnNotEnabledException` : The user selected passkey authentication but it's not enabled.
    /// - `WebAuthnOriginNotAllowedException` : The user presented passkey credentials from a device origin that isn't registered as an allowed origin. Registering allowed origins is optional.
    /// - `WebAuthnRelyingPartyMismatchException` : The user's passkey didn't have an entry for the current relying party ID.
    func completeWebAuthnRegistration(input: CompleteWebAuthnRegistrationInput) async throws -> CompleteWebAuthnRegistrationOutput
}
