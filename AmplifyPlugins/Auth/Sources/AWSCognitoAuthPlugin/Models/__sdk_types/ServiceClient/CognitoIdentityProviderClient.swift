//
//  File.swift
//  
//
//  Created by Saultz, Ian on 10/26/23.
//

import Foundation

public struct CognitoIdentityProviderClientConfiguration {
    let region: String
    let endpointResolver: EndpointResolver?
}

public class CognitoIdentityProviderClient {
    let configuration: CognitoIdentityProviderClientConfiguration

    init(configuration: CognitoIdentityProviderClientConfiguration) {
        self.configuration = configuration
    }
}

#error("Write request implementation")
extension CognitoIdentityProviderClient: CognitoUserPoolBehavior {
    /// Throws InitiateAuthOutputError
    func initiateAuth(input: InitiateAuthInput) async throws -> InitiateAuthOutputResponse  {
        fatalError()
    }

    /// Throws RespondToAuthChallengeOutputError
    func respondToAuthChallenge(
        input: RespondToAuthChallengeInput
    ) async throws -> RespondToAuthChallengeOutputResponse {
        fatalError()
    }

    /// Throws SignUpOutputError
    func signUp(input: SignUpInput) async throws -> SignUpOutputResponse {
        fatalError()
    }

    /// Throws ConfirmSignUpOutputError
    func confirmSignUp(input: ConfirmSignUpInput) async throws -> ConfirmSignUpOutputResponse {
        fatalError()
    }

    /// Throws GlobalSignOutOutputError
    func globalSignOut(input: GlobalSignOutInput) async throws -> GlobalSignOutOutputResponse {
        fatalError()
    }

    /// Throws RevokeTokenOutputError
    func revokeToken(input: RevokeTokenInput) async throws -> RevokeTokenOutputResponse {
        fatalError()
    }

    // MARK: - User Attribute API's

    /// Throws GetUserAttributeVerificationCodeOutputError
    func getUserAttributeVerificationCode(input: GetUserAttributeVerificationCodeInput) async throws -> GetUserAttributeVerificationCodeOutputResponse {
        fatalError()
    }

    /// Throws GetUserOutputError
    func getUser(input: GetUserInput) async throws -> GetUserOutputResponse {
        fatalError()
    }

    /// Throws UpdateUserAttributesOutputError
    func updateUserAttributes(input: UpdateUserAttributesInput) async throws -> UpdateUserAttributesOutputResponse {
        fatalError()
    }

    /// Verifies the specified user attributes in the user pool.
    /// Throws VerifyUserAttributeOutputError
    func verifyUserAttribute(input: VerifyUserAttributeInput) async throws -> VerifyUserAttributeOutputResponse {
        fatalError()
    }

    /// Changes the password for a specified user in a user pool.
    /// Throws ChangePasswordOutputError
    func changePassword(input: ChangePasswordInput) async throws -> ChangePasswordOutputResponse {
        fatalError()
    }

    /// Delete the signed in user from the user pool.
    /// Throws DeleteUserOutputError
    func deleteUser(input: DeleteUserInput) async throws -> DeleteUserOutputResponse {
        fatalError()
    }

    /// Resends sign up code
    /// Throws ResendConfirmationCodeOutputError
    func resendConfirmationCode(input: ResendConfirmationCodeInput) async throws -> ResendConfirmationCodeOutputResponse {
        fatalError()
    }

    /// Resets password
    /// Throws ForgotPasswordOutputError
    func forgotPassword(input: ForgotPasswordInput) async throws -> ForgotPasswordOutputResponse {
        fatalError()
    }

    /// Confirm Reset password
    /// Throws ConfirmForgotPasswordOutputError
    func confirmForgotPassword(input: ConfirmForgotPasswordInput) async throws -> ConfirmForgotPasswordOutputResponse {
        fatalError()
    }

    /// Lists the devices
    func listDevices(input: ListDevicesInput) async throws -> ListDevicesOutputResponse {
        fatalError()
    }

    /// Updates the device status
    func updateDeviceStatus(input: UpdateDeviceStatusInput) async throws -> UpdateDeviceStatusOutputResponse {
        fatalError()
    }

    /// Forgets the specified device.
    func forgetDevice(input: ForgetDeviceInput) async throws -> ForgetDeviceOutputResponse {
        fatalError()
    }

    /// Confirms tracking of the device. This API call is the call that begins device tracking.
    /// Throws ConfirmDeviceOutputError
    func confirmDevice(input: ConfirmDeviceInput) async throws -> ConfirmDeviceOutputResponse {
        fatalError()
    }

    /// Creates a new request to associate a new software token for the user
    /// Throws AssociateSoftwareTokenOutputError
    func associateSoftwareToken(input: AssociateSoftwareTokenInput) async throws -> AssociateSoftwareTokenOutputResponse {
        fatalError()
    }

    /// Register a user's entered time-based one-time password (TOTP) code and mark the user's software token MFA status as "verified" if successful.
    /// Throws VerifySoftwareTokenOutputError
    func verifySoftwareToken(input: VerifySoftwareTokenInput) async throws -> VerifySoftwareTokenOutputResponse {
        fatalError()
    }

    /// Set the user's multi-factor authentication (MFA) method preference, including which MFA factors are activated and if any are preferred.
    /// Throws SetUserMFAPreferenceOutputError
    func setUserMFAPreference(input: SetUserMFAPreferenceInput) async throws -> SetUserMFAPreferenceOutputResponse {
        fatalError()
    }
}
