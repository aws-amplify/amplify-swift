//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

@testable import AWSCognitoAuthPlugin
import AWSCognitoIdentityProvider
import ClientRuntime

struct MockIdentityProvider: CognitoUserPoolBehavior {

    typealias MockSignUpResponse = (SignUpInput) async throws
    -> SignUpOutputResponse

    typealias MockRevokeTokenResponse = (RevokeTokenInput) async throws
    -> RevokeTokenOutputResponse

    typealias MockInitiateAuthResponse = (InitiateAuthInput) async throws
    -> InitiateAuthOutputResponse

    typealias MockConfirmSignUpResponse = (ConfirmSignUpInput) async throws
    -> ConfirmSignUpOutputResponse

    typealias MockGlobalSignOutResponse = (GlobalSignOutInput) async throws
    -> GlobalSignOutOutputResponse

    typealias MockRespondToAuthChallengeResponse = (RespondToAuthChallengeInput) async throws
    -> RespondToAuthChallengeOutputResponse

    typealias MockGetUserAttributeVerificationCodeOutputResponse = (GetUserAttributeVerificationCodeInput) async throws
    -> GetUserAttributeVerificationCodeOutputResponse

    typealias MockGetUserAttributesOutputResponse = (GetUserInput) async throws
    -> GetUserOutputResponse

    typealias MockUpdateUserAttributesOutputResponse = (UpdateUserAttributesInput) async throws
    -> UpdateUserAttributesOutputResponse

    typealias MockConfirmUserAttributeOutputResponse = (VerifyUserAttributeInput) async throws
    -> VerifyUserAttributeOutputResponse

    typealias MockChangePasswordOutputResponse = (ChangePasswordInput) async throws
    -> ChangePasswordOutputResponse

    typealias MockResendConfirmationCodeOutputResponse = (ResendConfirmationCodeInput) async throws
    -> ResendConfirmationCodeOutputResponse

    typealias MockForgotPasswordOutputResponse = (ForgotPasswordInput) async throws
    -> ForgotPasswordOutputResponse

    typealias MockDeleteUserOutputResponse = (DeleteUserInput) async throws
    -> DeleteUserOutputResponse

    typealias MockConfirmForgotPasswordOutputResponse = (ConfirmForgotPasswordInput) async throws
    -> ConfirmForgotPasswordOutputResponse

    typealias MockListDevicesOutputResponse = (ListDevicesInput) async throws
    -> ListDevicesOutputResponse

    typealias MockRememberDeviceResponse = (UpdateDeviceStatusInput) async throws
    -> UpdateDeviceStatusOutputResponse

    typealias MockForgetDeviceResponse = (ForgetDeviceInput) async throws
    -> ForgetDeviceOutputResponse

    typealias MockConfirmDeviceResponse = (ConfirmDeviceInput) async throws
    -> ConfirmDeviceOutputResponse

    typealias MockSetUserMFAPreferenceResponse = (SetUserMFAPreferenceInput) async throws
    -> SetUserMFAPreferenceOutputResponse

    typealias MockAssociateSoftwareTokenResponse = (AssociateSoftwareTokenInput) async throws
    -> AssociateSoftwareTokenOutputResponse

    typealias MockVerifySoftwareTokenResponse = (VerifySoftwareTokenInput) async throws
    -> VerifySoftwareTokenOutputResponse

    let mockSignUpResponse: MockSignUpResponse?
    let mockRevokeTokenResponse: MockRevokeTokenResponse?
    let mockInitiateAuthResponse: MockInitiateAuthResponse?
    let mockGlobalSignOutResponse: MockGlobalSignOutResponse?
    let mockConfirmSignUpResponse: MockConfirmSignUpResponse?
    let mockRespondToAuthChallengeResponse: MockRespondToAuthChallengeResponse?
    let mockGetUserAttributeVerificationCodeOutputResponse: MockGetUserAttributeVerificationCodeOutputResponse?
    let mockGetUserAttributeResponse: MockGetUserAttributesOutputResponse?
    let mockUpdateUserAttributeResponse: MockUpdateUserAttributesOutputResponse?
    let mockConfirmUserAttributeOutputResponse: MockConfirmUserAttributeOutputResponse?
    let mockChangePasswordOutputResponse: MockChangePasswordOutputResponse?
    let mockResendConfirmationCodeOutputResponse: MockResendConfirmationCodeOutputResponse?
    let mockDeleteUserOutputResponse: MockDeleteUserOutputResponse?
    let mockForgotPasswordOutputResponse: MockForgotPasswordOutputResponse?
    let mockConfirmForgotPasswordOutputResponse: MockConfirmForgotPasswordOutputResponse?
    let mockListDevicesOutputResponse: MockListDevicesOutputResponse?
    let mockRememberDeviceResponse: MockRememberDeviceResponse?
    let mockForgetDeviceResponse: MockForgetDeviceResponse?
    let mockConfirmDeviceResponse: MockConfirmDeviceResponse?
    let mockSetUserMFAPreferenceResponse: MockSetUserMFAPreferenceResponse?
    let mockAssociateSoftwareTokenResponse: MockAssociateSoftwareTokenResponse?
    let mockVerifySoftwareTokenResponse: MockVerifySoftwareTokenResponse?

    init(
        mockSignUpResponse: MockSignUpResponse? = nil,
        mockRevokeTokenResponse: MockRevokeTokenResponse? = nil,
        mockInitiateAuthResponse: MockInitiateAuthResponse? = nil,
        mockGlobalSignOutResponse: MockGlobalSignOutResponse? = nil,
        mockConfirmSignUpResponse: MockConfirmSignUpResponse? = nil,
        mockRespondToAuthChallengeResponse: MockRespondToAuthChallengeResponse? = nil,
        mockGetUserAttributeVerificationCodeOutputResponse: MockGetUserAttributeVerificationCodeOutputResponse? = nil,
        mockGetUserAttributeResponse: MockGetUserAttributesOutputResponse? = nil,
        mockUpdateUserAttributeResponse: MockUpdateUserAttributesOutputResponse? = nil,
        mockConfirmUserAttributeOutputResponse: MockConfirmUserAttributeOutputResponse? = nil,
        mockChangePasswordOutputResponse: MockChangePasswordOutputResponse? = nil,
        mockResendConfirmationCodeOutputResponse: MockResendConfirmationCodeOutputResponse? = nil,
        mockDeleteUserOutputResponse: MockDeleteUserOutputResponse? = nil,
        mockForgotPasswordOutputResponse: MockForgotPasswordOutputResponse? = nil,
        mockConfirmForgotPasswordOutputResponse: MockConfirmForgotPasswordOutputResponse? = nil,
        mockListDevicesOutputResponse: MockListDevicesOutputResponse? = nil,
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
        self.mockGlobalSignOutResponse = mockGlobalSignOutResponse
        self.mockConfirmSignUpResponse = mockConfirmSignUpResponse
        self.mockRespondToAuthChallengeResponse = mockRespondToAuthChallengeResponse
        self.mockGetUserAttributeVerificationCodeOutputResponse = mockGetUserAttributeVerificationCodeOutputResponse
        self.mockGetUserAttributeResponse = mockGetUserAttributeResponse
        self.mockUpdateUserAttributeResponse = mockUpdateUserAttributeResponse
        self.mockConfirmUserAttributeOutputResponse = mockConfirmUserAttributeOutputResponse
        self.mockChangePasswordOutputResponse = mockChangePasswordOutputResponse
        self.mockResendConfirmationCodeOutputResponse = mockResendConfirmationCodeOutputResponse
        self.mockDeleteUserOutputResponse = mockDeleteUserOutputResponse
        self.mockForgotPasswordOutputResponse = mockForgotPasswordOutputResponse
        self.mockConfirmForgotPasswordOutputResponse = mockConfirmForgotPasswordOutputResponse
        self.mockListDevicesOutputResponse = mockListDevicesOutputResponse
        self.mockRememberDeviceResponse = mockRememberDeviceResponse
        self.mockForgetDeviceResponse = mockForgetDeviceResponse
        self.mockConfirmDeviceResponse = mockConfirmDeviceResponse
        self.mockSetUserMFAPreferenceResponse = mockSetUserMFAPreferenceResponse
        self.mockAssociateSoftwareTokenResponse = mockAssociateSoftwareTokenResponse
        self.mockVerifySoftwareTokenResponse = mockVerifySoftwareTokenResponse
    }

    /// Throws InitiateAuthOutputError
    func initiateAuth(input: InitiateAuthInput) async throws -> InitiateAuthOutputResponse {
        return try await mockInitiateAuthResponse!(input)
    }

    /// Throws RespondToAuthChallengeOutputError
    func respondToAuthChallenge(
        input: RespondToAuthChallengeInput
    ) async throws -> RespondToAuthChallengeOutputResponse {
        return try await mockRespondToAuthChallengeResponse!(input)
    }

    /// Throws SignUpOutputError
    func signUp(input: SignUpInput) async throws -> SignUpOutputResponse {
        return try await mockSignUpResponse!(input)
    }

    /// Throws ConfirmSignUpOutputError
    func confirmSignUp(input: ConfirmSignUpInput) async throws -> ConfirmSignUpOutputResponse {
        return try await mockConfirmSignUpResponse!(input)
    }

    /// Throws GlobalSignOutOutputError
    func globalSignOut(input: GlobalSignOutInput) async throws -> GlobalSignOutOutputResponse {
        return try await mockGlobalSignOutResponse!(input)
    }

    /// Throws RevokeTokenOutputError
    func revokeToken(input: RevokeTokenInput) async throws -> RevokeTokenOutputResponse {
        return try await mockRevokeTokenResponse!(input)
    }

    func getUserAttributeVerificationCode(input: GetUserAttributeVerificationCodeInput) async throws -> GetUserAttributeVerificationCodeOutputResponse {
        return try await mockGetUserAttributeVerificationCodeOutputResponse!(input)
    }

    func getUser(input: GetUserInput) async throws -> GetUserOutputResponse {
        return try await mockGetUserAttributeResponse!(input)
    }

    func updateUserAttributes(input: UpdateUserAttributesInput) async throws -> UpdateUserAttributesOutputResponse {
        return try await mockUpdateUserAttributeResponse!(input)
    }

    func verifyUserAttribute(input: VerifyUserAttributeInput) async throws -> VerifyUserAttributeOutputResponse {
        return try await mockConfirmUserAttributeOutputResponse!(input)
    }

    func changePassword(input: ChangePasswordInput) async throws -> ChangePasswordOutputResponse {
        return try await mockChangePasswordOutputResponse!(input)
    }

    func resendConfirmationCode(input: ResendConfirmationCodeInput) async throws -> ResendConfirmationCodeOutputResponse {
        return try await mockResendConfirmationCodeOutputResponse!(input)
    }

    func deleteUser(input: DeleteUserInput) async throws -> DeleteUserOutputResponse {
        return try await mockDeleteUserOutputResponse!(input)
    }

    func forgotPassword(input: ForgotPasswordInput) async throws -> ForgotPasswordOutputResponse {
        return try await mockForgotPasswordOutputResponse!(input)
    }

    func confirmForgotPassword(input: ConfirmForgotPasswordInput) async throws -> ConfirmForgotPasswordOutputResponse {
        return try await mockConfirmForgotPasswordOutputResponse!(input)
    }

    func listDevices(input: ListDevicesInput) async throws -> ListDevicesOutputResponse {
        return try await mockListDevicesOutputResponse!(input)
    }

    func updateDeviceStatus(input: UpdateDeviceStatusInput) async throws -> UpdateDeviceStatusOutputResponse {
        return try await mockRememberDeviceResponse!(input)
    }

    func forgetDevice(input: ForgetDeviceInput) async throws -> ForgetDeviceOutputResponse {
        return try await mockForgetDeviceResponse!(input)
    }

    func confirmDevice(input: ConfirmDeviceInput) async throws -> ConfirmDeviceOutputResponse {
        return try await mockConfirmDeviceResponse!(input)
    }

    func associateSoftwareToken(input: AWSCognitoIdentityProvider.AssociateSoftwareTokenInput) async throws -> AWSCognitoIdentityProvider.AssociateSoftwareTokenOutputResponse {
        return try await mockAssociateSoftwareTokenResponse!(input)
    }

    func verifySoftwareToken(input: AWSCognitoIdentityProvider.VerifySoftwareTokenInput) async throws -> AWSCognitoIdentityProvider.VerifySoftwareTokenOutputResponse {
        return try await mockVerifySoftwareTokenResponse!(input)
    }

    func setUserMFAPreference(input: SetUserMFAPreferenceInput) async throws -> SetUserMFAPreferenceOutputResponse {
        return try await mockSetUserMFAPreferenceResponse!(input)
    }
}
