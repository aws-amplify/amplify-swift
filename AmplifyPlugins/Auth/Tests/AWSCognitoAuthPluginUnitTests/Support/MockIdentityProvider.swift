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

    let mockSignUpResponse: MockSignUpResponse?
    let mockRevokeTokenResponse: MockRevokeTokenResponse?
    let mockInitiateAuthResponse: MockInitiateAuthResponse?
    let mockGlobalSignOutResponse: MockGlobalSignOutResponse?
    let mockConfirmSignUpResponse: MockConfirmSignUpResponse?
    let mockRespondToAuthChallengeResponse: MockRespondToAuthChallengeResponse?

    init(
        mockSignUpResponse: MockSignUpResponse? = nil,
        mockRevokeTokenResponse: MockRevokeTokenResponse? = nil,
        mockInitiateAuthResponse: MockInitiateAuthResponse? = nil,
        mockGlobalSignOutResponse: MockGlobalSignOutResponse? = nil,
        mockConfirmSignUpResponse: MockConfirmSignUpResponse? = nil,
        mockRespondToAuthChallengeResponse: MockRespondToAuthChallengeResponse? = nil
    ) {
        self.mockSignUpResponse = mockSignUpResponse
        self.mockRevokeTokenResponse = mockRevokeTokenResponse
        self.mockInitiateAuthResponse = mockInitiateAuthResponse
        self.mockGlobalSignOutResponse = mockGlobalSignOutResponse
        self.mockConfirmSignUpResponse = mockConfirmSignUpResponse
        self.mockRespondToAuthChallengeResponse = mockRespondToAuthChallengeResponse
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
}
