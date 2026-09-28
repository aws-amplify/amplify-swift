//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import InternalAWSCognitoAuth
@_spi(AmplifyExperimental) @testable import AmplifyCognitoClient

/// A test engine that wraps another and changes only its sign-in behaviour (`CancelHoldingEngine`): every
/// Phase 5 seam method forwards to `phase5Base` unchanged, so a wrapper needs only name its base.
protocol Phase5Forwarding: SessionEngine {
    var phase5Base: any SessionEngine { get }
}

extension Phase5Forwarding {

    // The hosted UI forwards too: a wrapper changes sign-in behaviour only.

    func signOutPresentsBrowser(_ payload: Data) throws -> Bool {
        try phase5Base.signOutPresentsBrowser(payload)
    }

    // The challenge record forwards too.

    var pendingChallengeState: ChallengeRecord.State? {
        get async { await phase5Base.pendingChallengeState }
    }

    func resumeSignIn(from state: ChallengeRecord.State, epoch: UInt64) async -> AuthClientSignInStep? {
        await phase5Base.resumeSignIn(from: state, epoch: epoch)
    }

    func signInWithWebUI(_ request: EngineWebUISignInRequest, current: Data?, epoch: UInt64) async throws -> EngineStepResult {
        try await phase5Base.signInWithWebUI(request, current: current, epoch: epoch)
    }

    func revoke(_ payload: Data, global: Bool, hostedUI: EngineHostedUISignOut) async throws -> EngineSignOutOutcome {
        try await phase5Base.revoke(payload, global: global, hostedUI: hostedUI)
    }

    func signUp(_ request: EngineSignUpRequest) async throws -> AuthClientSignUpResult {
        try await phase5Base.signUp(request)
    }

    func confirmSignUp(_ request: EngineConfirmSignUpRequest) async throws -> AuthClientSignUpResult {
        try await phase5Base.confirmSignUp(request)
    }

    func resendSignUpCode(username: String, clientMetadata: [String: String]) async throws -> AuthClientCodeDeliveryDetails {
        try await phase5Base.resendSignUpCode(username: username, clientMetadata: clientMetadata)
    }

    var hasAutoSignInSession: Bool {
        get async { await phase5Base.hasAutoSignInSession }
    }

    func autoSignIn(current: Data?, epoch: UInt64) async throws -> EngineStepResult {
        try await phase5Base.autoSignIn(current: current, epoch: epoch)
    }

    func resetPassword(username: String, clientMetadata: [String: String]) async throws -> AuthClientResetPasswordResult {
        try await phase5Base.resetPassword(username: username, clientMetadata: clientMetadata)
    }

    func confirmResetPassword(_ request: EngineConfirmResetPasswordRequest) async throws {
        try await phase5Base.confirmResetPassword(request)
    }

    func fetchUserAttributes(_ payload: Data) async throws -> [AuthClientUserAttribute] {
        try await phase5Base.fetchUserAttributes(payload)
    }

    func updateUserAttributes(
        _ payload: Data,
        attributes: [AuthClientUserAttribute],
        clientMetadata: [String: String]
    ) async throws -> [AuthClientUserAttributeKey: AuthClientUpdateAttributeResult] {
        try await phase5Base.updateUserAttributes(payload, attributes: attributes, clientMetadata: clientMetadata)
    }

    func sendVerificationCode(
        _ payload: Data,
        attributeKey: AuthClientUserAttributeKey,
        clientMetadata: [String: String]
    ) async throws -> AuthClientCodeDeliveryDetails {
        try await phase5Base.sendVerificationCode(payload, attributeKey: attributeKey, clientMetadata: clientMetadata)
    }

    func confirmUserAttribute(_ payload: Data, attributeKey: AuthClientUserAttributeKey, confirmationCode: String) async throws {
        try await phase5Base.confirmUserAttribute(payload, attributeKey: attributeKey, confirmationCode: confirmationCode)
    }

    func changePassword(_ payload: Data, oldPassword: String, newPassword: String) async throws {
        try await phase5Base.changePassword(payload, oldPassword: oldPassword, newPassword: newPassword)
    }

    func setUpTOTP(_ payload: Data) async throws -> AuthClientTOTPSetupDetails {
        try await phase5Base.setUpTOTP(payload)
    }

    func verifyTOTPSetup(_ payload: Data, code: String, friendlyDeviceName: String?) async throws {
        try await phase5Base.verifyTOTPSetup(payload, code: code, friendlyDeviceName: friendlyDeviceName)
    }

    func fetchMFAPreference(_ payload: Data) async throws -> AuthClientUserMFAPreference {
        try await phase5Base.fetchMFAPreference(payload)
    }

    func updateMFAPreference(
        _ payload: Data,
        sms: AuthClientMFAPreference?,
        totp: AuthClientMFAPreference?,
        email: AuthClientMFAPreference?
    ) async throws {
        try await phase5Base.updateMFAPreference(payload, sms: sms, totp: totp, email: email)
    }

    func fetchDevices(_ payload: Data) async throws -> [AuthClientDevice] {
        try await phase5Base.fetchDevices(payload)
    }

    func rememberDevice(_ payload: Data) async throws {
        try await phase5Base.rememberDevice(payload)
    }

    func forgetDevice(_ payload: Data, deviceId: String?) async throws {
        try await phase5Base.forgetDevice(payload, deviceId: deviceId)
    }

    func federateToIdentityPool(_ request: EngineFederationRequest, current: Data?) async throws -> Data {
        try await phase5Base.federateToIdentityPool(request, current: current)
    }

    func associateWebAuthnCredential(_ payload: Data, context: EngineCeremonyContext) async throws {
        try await phase5Base.associateWebAuthnCredential(payload, context: context)
    }

    func listWebAuthnCredentials(_ payload: Data, pageSize: Int, nextToken: String?) async throws -> EngineWebAuthnCredentialPage {
        try await phase5Base.listWebAuthnCredentials(payload, pageSize: pageSize, nextToken: nextToken)
    }

    func deleteWebAuthnCredential(_ payload: Data, credentialId: String) async throws {
        try await phase5Base.deleteWebAuthnCredential(payload, credentialId: credentialId)
    }
}
