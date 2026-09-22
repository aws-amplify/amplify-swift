//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AWSCognitoIdentityProvider
import ClientRuntime
@testable import AWSCognitoAuthPlugin

struct MockIdentityProvider: CognitoUserPoolBehavior {

    typealias MockSignUpResponse = @Sendable (SignUpInput) async throws
    -> SignUpOutput

    typealias MockRevokeTokenResponse = @Sendable (RevokeTokenInput) async throws
    -> RevokeTokenOutput

    typealias MockInitiateAuthResponse = @Sendable (InitiateAuthInput) async throws
    -> InitiateAuthOutput

    typealias MockGetTokensFromRefreshTokenResponse = @Sendable (GetTokensFromRefreshTokenInput) async throws
    -> GetTokensFromRefreshTokenOutput

    typealias MockConfirmSignUpResponse = @Sendable (ConfirmSignUpInput) async throws
    -> ConfirmSignUpOutput

    typealias MockGlobalSignOutResponse = @Sendable (GlobalSignOutInput) async throws
    -> GlobalSignOutOutput

    typealias MockRespondToAuthChallengeResponse = @Sendable (RespondToAuthChallengeInput) async throws
    -> RespondToAuthChallengeOutput

    typealias MockGetUserAttributeVerificationCodeOutput = @Sendable (GetUserAttributeVerificationCodeInput) async throws
    -> GetUserAttributeVerificationCodeOutput

    typealias MockGetUserAttributesOutput = @Sendable (GetUserInput) async throws
    -> GetUserOutput

    typealias MockUpdateUserAttributesOutput = @Sendable (UpdateUserAttributesInput) async throws
    -> UpdateUserAttributesOutput

    typealias MockConfirmUserAttributeOutput = @Sendable (VerifyUserAttributeInput) async throws
    -> VerifyUserAttributeOutput

    typealias MockChangePasswordOutput = @Sendable (ChangePasswordInput) async throws
    -> ChangePasswordOutput

    typealias MockResendConfirmationCodeOutput = @Sendable (ResendConfirmationCodeInput) async throws
    -> ResendConfirmationCodeOutput

    typealias MockForgotPasswordOutput = @Sendable (ForgotPasswordInput) async throws
    -> ForgotPasswordOutput

    typealias MockDeleteUserOutput = @Sendable (DeleteUserInput) async throws
    -> DeleteUserOutput

    typealias MockConfirmForgotPasswordOutput = @Sendable (ConfirmForgotPasswordInput) async throws
    -> ConfirmForgotPasswordOutput

    typealias MockListDevicesOutput = @Sendable (ListDevicesInput) async throws
    -> ListDevicesOutput

    typealias MockRememberDeviceResponse = @Sendable (UpdateDeviceStatusInput) async throws
    -> UpdateDeviceStatusOutput

    typealias MockForgetDeviceResponse = @Sendable (ForgetDeviceInput) async throws
    -> ForgetDeviceOutput

    typealias MockConfirmDeviceResponse = @Sendable (ConfirmDeviceInput) async throws
    -> ConfirmDeviceOutput

    typealias MockSetUserMFAPreferenceResponse = @Sendable (SetUserMFAPreferenceInput) async throws
    -> SetUserMFAPreferenceOutput

    typealias MockAssociateSoftwareTokenResponse = @Sendable (AssociateSoftwareTokenInput) async throws
    -> AssociateSoftwareTokenOutput

    typealias MockVerifySoftwareTokenResponse = @Sendable (VerifySoftwareTokenInput) async throws
    -> VerifySoftwareTokenOutput

    typealias MockListWebAuthnCredentialsResponse = @Sendable (ListWebAuthnCredentialsInput) async throws -> ListWebAuthnCredentialsOutput

    typealias MockDeleteWebAuthnCredentialResponse = @Sendable (DeleteWebAuthnCredentialInput) async throws -> DeleteWebAuthnCredentialOutput

    typealias MockStartWebAuthnRegistrationResponse = @Sendable (StartWebAuthnRegistrationInput) async throws -> StartWebAuthnRegistrationOutput

    typealias MockCompletetWebAuthnRegistrationResponse = @Sendable (CompleteWebAuthnRegistrationInput) async throws -> CompleteWebAuthnRegistrationOutput

    let mockSignUpResponse: MockSignUpResponse?
    let mockRevokeTokenResponse: MockRevokeTokenResponse?
    let mockInitiateAuthResponse: MockInitiateAuthResponse?
    let mockGetTokensFromRefreshTokenResponse: MockGetTokensFromRefreshTokenResponse?
    let mockGlobalSignOutResponse: MockGlobalSignOutResponse?
    let mockConfirmSignUpResponse: MockConfirmSignUpResponse?
    let mockRespondToAuthChallengeResponse: MockRespondToAuthChallengeResponse?
    let mockGetUserAttributeVerificationCodeOutput: MockGetUserAttributeVerificationCodeOutput?
    let mockGetUserAttributeResponse: MockGetUserAttributesOutput?
    let mockUpdateUserAttributeResponse: MockUpdateUserAttributesOutput?
    let mockConfirmUserAttributeOutput: MockConfirmUserAttributeOutput?
    let mockChangePasswordOutput: MockChangePasswordOutput?
    let mockResendConfirmationCodeOutput: MockResendConfirmationCodeOutput?
    let mockDeleteUserOutput: MockDeleteUserOutput?
    let mockForgotPasswordOutput: MockForgotPasswordOutput?
    let mockConfirmForgotPasswordOutput: MockConfirmForgotPasswordOutput?
    let mockListDevicesOutput: MockListDevicesOutput?
    let mockRememberDeviceResponse: MockRememberDeviceResponse?
    let mockForgetDeviceResponse: MockForgetDeviceResponse?
    let mockConfirmDeviceResponse: MockConfirmDeviceResponse?
    let mockSetUserMFAPreferenceResponse: MockSetUserMFAPreferenceResponse?
    let mockAssociateSoftwareTokenResponse: MockAssociateSoftwareTokenResponse?
    let mockVerifySoftwareTokenResponse: MockVerifySoftwareTokenResponse?
    var mockListWebAuthnCredentialsResponse: MockListWebAuthnCredentialsResponse?
    var mockDeleteWebAuthnCredentialResponse: MockDeleteWebAuthnCredentialResponse?
    var mockStartWebAuthnRegistrationResponse: MockStartWebAuthnRegistrationResponse?
    var mockCompleteWebAuthnRegistrationResponse: MockCompletetWebAuthnRegistrationResponse?

    init(
        mockSignUpResponse: MockSignUpResponse? = nil,
        mockRevokeTokenResponse: MockRevokeTokenResponse? = nil,
        mockInitiateAuthResponse: MockInitiateAuthResponse? = nil,
        mockGetTokensFromRefreshTokenResponse: MockGetTokensFromRefreshTokenResponse? = nil,
        mockGlobalSignOutResponse: MockGlobalSignOutResponse? = nil,
        mockConfirmSignUpResponse: MockConfirmSignUpResponse? = nil,
        mockRespondToAuthChallengeResponse: MockRespondToAuthChallengeResponse? = nil,
        mockGetUserAttributeVerificationCodeOutput: MockGetUserAttributeVerificationCodeOutput? = nil,
        mockGetUserAttributeResponse: MockGetUserAttributesOutput? = nil,
        mockUpdateUserAttributeResponse: MockUpdateUserAttributesOutput? = nil,
        mockConfirmUserAttributeOutput: MockConfirmUserAttributeOutput? = nil,
        mockChangePasswordOutput: MockChangePasswordOutput? = nil,
        mockResendConfirmationCodeOutput: MockResendConfirmationCodeOutput? = nil,
        mockDeleteUserOutput: MockDeleteUserOutput? = nil,
        mockForgotPasswordOutput: MockForgotPasswordOutput? = nil,
        mockConfirmForgotPasswordOutput: MockConfirmForgotPasswordOutput? = nil,
        mockListDevicesOutput: MockListDevicesOutput? = nil,
        mockRememberDeviceResponse: MockRememberDeviceResponse? = nil,
        mockForgetDeviceResponse: MockForgetDeviceResponse? = nil,
        mockConfirmDeviceResponse: MockConfirmDeviceResponse? = nil,
        mockSetUserMFAPreferenceResponse: MockSetUserMFAPreferenceResponse? = nil,
        mockAssociateSoftwareTokenResponse: MockAssociateSoftwareTokenResponse? = nil,
        mockVerifySoftwareTokenResponse: MockVerifySoftwareTokenResponse? = nil
    ) {
        self.mockSignUpResponse = mockSignUpResponse
        self.mockRevokeTokenResponse = mockRevokeTokenResponse
        self.mockInitiateAuthResponse = mockInitiateAuthResponse
        self.mockGetTokensFromRefreshTokenResponse = mockGetTokensFromRefreshTokenResponse
        self.mockGlobalSignOutResponse = mockGlobalSignOutResponse
        self.mockConfirmSignUpResponse = mockConfirmSignUpResponse
        self.mockRespondToAuthChallengeResponse = mockRespondToAuthChallengeResponse
        self.mockGetUserAttributeVerificationCodeOutput = mockGetUserAttributeVerificationCodeOutput
        self.mockGetUserAttributeResponse = mockGetUserAttributeResponse
        self.mockUpdateUserAttributeResponse = mockUpdateUserAttributeResponse
        self.mockConfirmUserAttributeOutput = mockConfirmUserAttributeOutput
        self.mockChangePasswordOutput = mockChangePasswordOutput
        self.mockResendConfirmationCodeOutput = mockResendConfirmationCodeOutput
        self.mockDeleteUserOutput = mockDeleteUserOutput
        self.mockForgotPasswordOutput = mockForgotPasswordOutput
        self.mockConfirmForgotPasswordOutput = mockConfirmForgotPasswordOutput
        self.mockListDevicesOutput = mockListDevicesOutput
        self.mockRememberDeviceResponse = mockRememberDeviceResponse
        self.mockForgetDeviceResponse = mockForgetDeviceResponse
        self.mockConfirmDeviceResponse = mockConfirmDeviceResponse
        self.mockSetUserMFAPreferenceResponse = mockSetUserMFAPreferenceResponse
        self.mockAssociateSoftwareTokenResponse = mockAssociateSoftwareTokenResponse
        self.mockVerifySoftwareTokenResponse = mockVerifySoftwareTokenResponse
    }

    /// Throws InitiateAuthOutputError
    func initiateAuth(input: InitiateAuthInput) async throws -> InitiateAuthOutput {
        return try await mockInitiateAuthResponse!(input)
    }

    /// Throws RespondToAuthChallengeOutputError
    func respondToAuthChallenge(
        input: RespondToAuthChallengeInput
    ) async throws -> RespondToAuthChallengeOutput {
        return try await mockRespondToAuthChallengeResponse!(input)
    }

    /// Throws SignUpOutputError
    func signUp(input: SignUpInput) async throws -> SignUpOutput {
        return try await mockSignUpResponse!(input)
    }

    /// Throws ConfirmSignUpOutputError
    func confirmSignUp(input: ConfirmSignUpInput) async throws -> ConfirmSignUpOutput {
        return try await mockConfirmSignUpResponse!(input)
    }

    /// Throws GlobalSignOutOutputError
    func globalSignOut(input: GlobalSignOutInput) async throws -> GlobalSignOutOutput {
        return try await mockGlobalSignOutResponse!(input)
    }

    /// Throws RevokeTokenOutputError
    func revokeToken(input: RevokeTokenInput) async throws -> RevokeTokenOutput {
        return try await mockRevokeTokenResponse!(input)
    }

    /// Throws GetTokensFromRefreshTokenOutputError
    func getTokensFromRefreshToken(input: GetTokensFromRefreshTokenInput) async throws -> GetTokensFromRefreshTokenOutput {
        return try await mockGetTokensFromRefreshTokenResponse!(input)
    }

    func getUserAttributeVerificationCode(input: GetUserAttributeVerificationCodeInput) async throws -> GetUserAttributeVerificationCodeOutput {
        return try await mockGetUserAttributeVerificationCodeOutput!(input)
    }

    func getUser(input: GetUserInput) async throws -> GetUserOutput {
        return try await mockGetUserAttributeResponse!(input)
    }

    func updateUserAttributes(input: UpdateUserAttributesInput) async throws -> UpdateUserAttributesOutput {
        return try await mockUpdateUserAttributeResponse!(input)
    }

    func verifyUserAttribute(input: VerifyUserAttributeInput) async throws -> VerifyUserAttributeOutput {
        return try await mockConfirmUserAttributeOutput!(input)
    }

    func changePassword(input: ChangePasswordInput) async throws -> ChangePasswordOutput {
        return try await mockChangePasswordOutput!(input)
    }

    func resendConfirmationCode(input: ResendConfirmationCodeInput) async throws -> ResendConfirmationCodeOutput {
        return try await mockResendConfirmationCodeOutput!(input)
    }

    func deleteUser(input: DeleteUserInput) async throws -> DeleteUserOutput {
        return try await mockDeleteUserOutput!(input)
    }

    func forgotPassword(input: ForgotPasswordInput) async throws -> ForgotPasswordOutput {
        return try await mockForgotPasswordOutput!(input)
    }

    func confirmForgotPassword(input: ConfirmForgotPasswordInput) async throws -> ConfirmForgotPasswordOutput {
        return try await mockConfirmForgotPasswordOutput!(input)
    }

    func listDevices(input: ListDevicesInput) async throws -> ListDevicesOutput {
        return try await mockListDevicesOutput!(input)
    }

    func updateDeviceStatus(input: UpdateDeviceStatusInput) async throws -> UpdateDeviceStatusOutput {
        return try await mockRememberDeviceResponse!(input)
    }

    func forgetDevice(input: ForgetDeviceInput) async throws -> ForgetDeviceOutput {
        return try await mockForgetDeviceResponse!(input)
    }

    func confirmDevice(input: ConfirmDeviceInput) async throws -> ConfirmDeviceOutput {
        return try await mockConfirmDeviceResponse!(input)
    }

    func associateSoftwareToken(input: AWSCognitoIdentityProvider.AssociateSoftwareTokenInput) async throws -> AWSCognitoIdentityProvider.AssociateSoftwareTokenOutput {
        return try await mockAssociateSoftwareTokenResponse!(input)
    }

    func verifySoftwareToken(input: AWSCognitoIdentityProvider.VerifySoftwareTokenInput) async throws -> AWSCognitoIdentityProvider.VerifySoftwareTokenOutput {
        return try await mockVerifySoftwareTokenResponse!(input)
    }

    func setUserMFAPreference(input: SetUserMFAPreferenceInput) async throws -> SetUserMFAPreferenceOutput {
        return try await mockSetUserMFAPreferenceResponse!(input)
    }

    func listWebAuthnCredentials(input: AWSCognitoIdentityProvider.ListWebAuthnCredentialsInput) async throws -> AWSCognitoIdentityProvider.ListWebAuthnCredentialsOutput {
        return try await mockListWebAuthnCredentialsResponse!(input)
    }

    func deleteWebAuthnCredential(input: AWSCognitoIdentityProvider.DeleteWebAuthnCredentialInput) async throws -> AWSCognitoIdentityProvider.DeleteWebAuthnCredentialOutput {
        return try await mockDeleteWebAuthnCredentialResponse!(input)
    }

    func startWebAuthnRegistration(input: AWSCognitoIdentityProvider.StartWebAuthnRegistrationInput) async throws -> AWSCognitoIdentityProvider.StartWebAuthnRegistrationOutput {
        return try await mockStartWebAuthnRegistrationResponse!(input)
    }

    func completeWebAuthnRegistration(input: AWSCognitoIdentityProvider.CompleteWebAuthnRegistrationInput) async throws -> AWSCognitoIdentityProvider.CompleteWebAuthnRegistrationOutput {
        return try await mockCompleteWebAuthnRegistrationResponse!(input)
    }

}
