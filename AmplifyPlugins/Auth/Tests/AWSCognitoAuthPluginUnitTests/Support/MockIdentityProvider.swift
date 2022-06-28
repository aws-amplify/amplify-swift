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
    let mockForgotPasswordOutputResponse: MockForgotPasswordOutputResponse?

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
        mockForgotPasswordOutputResponse: MockForgotPasswordOutputResponse? = nil
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
        self.mockForgotPasswordOutputResponse = mockForgotPasswordOutputResponse;
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
    
    func forgotPassword(input: ForgotPasswordInput) async throws -> ForgotPasswordOutputResponse {
        return try await mockForgotPasswordOutputResponse!(input)
    }
}
