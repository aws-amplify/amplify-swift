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
    func initiateAuth(input: InitiateAuthInput) async throws -> InitiateAuthOutputResponse

    /// Throws RespondToAuthChallengeOutputError
    func respondToAuthChallenge(
        input: RespondToAuthChallengeInput) async throws -> RespondToAuthChallengeOutputResponse

    /// Throws SignUpOutputError
    func signUp(input: SignUpInput) async throws -> SignUpOutputResponse

    /// Throws ConfirmSignUpOutputError
    func confirmSignUp(input: ConfirmSignUpInput) async throws -> ConfirmSignUpOutputResponse

    /// Throws GlobalSignOutOutputError
    func globalSignOut(input: GlobalSignOutInput) async throws -> GlobalSignOutOutputResponse

    /// Throws RevokeTokenOutputError
    func revokeToken(input: RevokeTokenInput) async throws -> RevokeTokenOutputResponse

    // MARK: - User Attribute API's

    /// Throws GetUserAttributeVerificationCodeOutputError
    func getUserAttributeVerificationCode(input: GetUserAttributeVerificationCodeInput) async throws -> GetUserAttributeVerificationCodeOutputResponse

    /// Throws GetUserOutputError
    func getUser(input: GetUserInput) async throws -> GetUserOutputResponse

    /// Throws UpdateUserAttributesOutputError
    func updateUserAttributes(input: UpdateUserAttributesInput) async throws -> UpdateUserAttributesOutputResponse

    /// Verifies the specified user attributes in the user pool.
    /// Throws VerifyUserAttributeOutputError
    func verifyUserAttribute(input: AWSCognitoIdentityProvider.VerifyUserAttributeInput) async throws -> AWSCognitoIdentityProvider.VerifyUserAttributeOutputResponse

    /// Changes the password for a specified user in a user pool.
    /// Throws ChangePasswordOutputError
    func changePassword(input: ChangePasswordInput) async throws -> ChangePasswordOutputResponse

    /// Delete the signed in user from the user pool.
    /// Throws DeleteUserOutputError
    func deleteUser(input: DeleteUserInput) async throws -> DeleteUserOutputResponse

    /// Resends sign up code
    /// Throws ResendConfirmationCodeOutputError
    func resendConfirmationCode(input: ResendConfirmationCodeInput) async throws -> ResendConfirmationCodeOutputResponse

    /// Resets password
    /// Throws ForgotPasswordOutputError
    func forgotPassword(input: ForgotPasswordInput) async throws -> ForgotPasswordOutputResponse

    /// Confirm Reset password
    /// Throws ConfirmForgotPasswordOutputError
    func confirmForgotPassword(input: ConfirmForgotPasswordInput) async throws -> ConfirmForgotPasswordOutputResponse

    /// Lists the devices
    func listDevices(input: ListDevicesInput) async throws -> ListDevicesOutputResponse

    /// Updates the device status
    func updateDeviceStatus(input: UpdateDeviceStatusInput) async throws -> UpdateDeviceStatusOutputResponse

    /// Forgets the specified device.
    func forgetDevice(input: ForgetDeviceInput) async throws -> ForgetDeviceOutputResponse

    /// Confirms tracking of the device. This API call is the call that begins device tracking.
    /// Throws ConfirmDeviceOutputError
    func confirmDevice(input: ConfirmDeviceInput) async throws -> ConfirmDeviceOutputResponse

    /// Creates a new request to associate a new software token for the user
    /// Throws AssociateSoftwareTokenOutputError
    func associateSoftwareToken(input: AssociateSoftwareTokenInput) async throws -> AssociateSoftwareTokenOutputResponse

    /// Register a user's entered time-based one-time password (TOTP) code and mark the user's software token MFA status as "verified" if successful.
    /// Throws VerifySoftwareTokenOutputError
    func verifySoftwareToken(input: VerifySoftwareTokenInput) async throws -> VerifySoftwareTokenOutputResponse

    /// Set the user's multi-factor authentication (MFA) method preference, including which MFA factors are activated and if any are preferred.
    /// Throws SetUserMFAPreferenceOutputError
    func setUserMFAPreference(input: SetUserMFAPreferenceInput) async throws -> SetUserMFAPreferenceOutputResponse

}
