//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import InternalAWSCognitoAuth
@_spi(AmplifyExperimental) @testable import AmplifyCognitoClient

/// Scripts one account operation: gets the call, returns the operation's result (`Void()` for none).
typealias FakeAccountOperationScript = @Sendable (FakeAccountOperationCall) async throws -> any Sendable

/// The account operations on the seam, one per `SessionEngine` method.
enum FakeAccountOperation: String, CaseIterable, Sendable {
    case signUp, confirmSignUp, resendSignUpCode, autoSignIn
    case resetPassword, confirmResetPassword
    case fetchUserAttributes, updateUserAttributes, sendVerificationCode, confirmUserAttribute, changePassword
    case setUpTOTP, verifyTOTPSetup, fetchMFAPreference, updateMFAPreference
    case fetchDevices, rememberDevice, forgetDevice
    case federateToIdentityPool
    case associateWebAuthnCredential, listWebAuthnCredentials, deleteWebAuthnCredential
}

/// One account-operation call as the fake engine received it. `payload` is the session's credentials payload the
/// core handed over, so a test can tell which session's user it was.
enum FakeAccountOperationCall: Equatable, Sendable {
    case signUp(EngineSignUpRequest)
    case confirmSignUp(EngineConfirmSignUpRequest)
    case resendSignUpCode(username: String, clientMetadata: [String: String])
    case autoSignIn(current: Data?, epoch: UInt64)
    case resetPassword(username: String, clientMetadata: [String: String])
    case confirmResetPassword(EngineConfirmResetPasswordRequest)
    case fetchUserAttributes(payload: Data)
    case updateUserAttributes(payload: Data, attributes: [AuthClientUserAttribute], clientMetadata: [String: String])
    case sendVerificationCode(payload: Data, attributeKey: AuthClientUserAttributeKey, clientMetadata: [String: String])
    case confirmUserAttribute(payload: Data, attributeKey: AuthClientUserAttributeKey, confirmationCode: String)
    case changePassword(payload: Data, oldPassword: String, newPassword: String)
    case setUpTOTP(payload: Data)
    case verifyTOTPSetup(payload: Data, code: String, friendlyDeviceName: String?)
    case fetchMFAPreference(payload: Data)
    case updateMFAPreference(payload: Data, sms: AuthClientMFAPreference?, totp: AuthClientMFAPreference?, email: AuthClientMFAPreference?)
    case fetchDevices(payload: Data)
    case rememberDevice(payload: Data)
    case forgetDevice(payload: Data, deviceId: String?)
    case federateToIdentityPool(EngineFederationRequest, current: Data?)
    case associateWebAuthnCredential(payload: Data, anchor: EnginePresentationAnchorBox?)
    case listWebAuthnCredentials(payload: Data, pageSize: Int, nextToken: String?)
    case deleteWebAuthnCredential(payload: Data, credentialId: String)

    var operation: FakeAccountOperation {
        guard let label = Mirror(reflecting: self).children.first?.label,
              let operation = FakeAccountOperation(rawValue: label) else {
            preconditionFailure("no operation for \(self)")
        }
        return operation
    }

    /// The credentials payload of a signed-in call, else `nil`.
    var payload: Data? {
        switch self {
        case .fetchUserAttributes(let payload),
             .updateUserAttributes(let payload, _, _),
             .sendVerificationCode(let payload, _, _),
             .confirmUserAttribute(let payload, _, _),
             .changePassword(let payload, _, _),
             .setUpTOTP(let payload),
             .verifyTOTPSetup(let payload, _, _),
             .fetchMFAPreference(let payload),
             .updateMFAPreference(let payload, _, _, _),
             .fetchDevices(let payload),
             .rememberDevice(let payload),
             .forgetDevice(let payload, _),
             .associateWebAuthnCredential(let payload, _),
             .listWebAuthnCredentials(let payload, _, _),
             .deleteWebAuthnCredential(let payload, _):
            return payload
        case .signUp, .confirmSignUp, .resendSignUpCode, .autoSignIn, .resetPassword, .confirmResetPassword,
             .federateToIdentityPool:
            return nil
        }
    }
}

/// The account-operation seam methods: each records its call and returns its script's result, or a default. The
/// defaults are a plain success. `autoSignIn` is in the main file, because it follows the sign-in contract.
extension FakeSessionEngine {

    static let delivery = AuthClientCodeDeliveryDetails(destination: .email("a***@example.com"), attributeKey: .email)

    func signUp(_ request: EngineSignUpRequest) async throws -> AuthClientSignUpResult {
        try await recordAccountOperation(.signUp(request), default: AuthClientSignUpResult(.done, userId: "sub-\(request.username)"))
    }

    func confirmSignUp(_ request: EngineConfirmSignUpRequest) async throws -> AuthClientSignUpResult {
        try await recordAccountOperation(.confirmSignUp(request), default: AuthClientSignUpResult(.done, userId: "sub-\(request.username)"))
    }

    func resendSignUpCode(username: String, clientMetadata: [String: String]) async throws -> AuthClientCodeDeliveryDetails {
        try await recordAccountOperation(.resendSignUpCode(username: username, clientMetadata: clientMetadata), default: Self.delivery)
    }

    func resetPassword(username: String, clientMetadata: [String: String]) async throws -> AuthClientResetPasswordResult {
        try await recordAccountOperation(
            .resetPassword(username: username, clientMetadata: clientMetadata),
            default: AuthClientResetPasswordResult(isPasswordReset: false, nextStep: .confirmResetPasswordWithCode(Self.delivery, nil))
        )
    }

    func confirmResetPassword(_ request: EngineConfirmResetPasswordRequest) async throws {
        try await recordAccountOperation(.confirmResetPassword(request), default: ())
    }

    func fetchUserAttributes(_ payload: Data) async throws -> [AuthClientUserAttribute] {
        let username = FakePayload.decode(payload)?.username ?? "unknown"
        return try await recordAccountOperation(.fetchUserAttributes(payload: payload), default: [AuthClientUserAttribute(.email, value: "\(username)@example.com")])
    }

    func updateUserAttributes(
        _ payload: Data,
        attributes: [AuthClientUserAttribute],
        clientMetadata: [String: String]
    ) async throws -> [AuthClientUserAttributeKey: AuthClientUpdateAttributeResult] {
        let done = AuthClientUpdateAttributeResult(isUpdated: true, nextStep: .done)
        return try await recordAccountOperation(
            .updateUserAttributes(payload: payload, attributes: attributes, clientMetadata: clientMetadata),
            default: Dictionary(attributes.map { ($0.key, done) }, uniquingKeysWith: { _, last in last })
        )
    }

    func sendVerificationCode(
        _ payload: Data,
        attributeKey: AuthClientUserAttributeKey,
        clientMetadata: [String: String]
    ) async throws -> AuthClientCodeDeliveryDetails {
        try await recordAccountOperation(
            .sendVerificationCode(payload: payload, attributeKey: attributeKey, clientMetadata: clientMetadata),
            default: Self.delivery
        )
    }

    func confirmUserAttribute(_ payload: Data, attributeKey: AuthClientUserAttributeKey, confirmationCode: String) async throws {
        try await recordAccountOperation(.confirmUserAttribute(payload: payload, attributeKey: attributeKey, confirmationCode: confirmationCode), default: ())
    }

    func changePassword(_ payload: Data, oldPassword: String, newPassword: String) async throws {
        try await recordAccountOperation(.changePassword(payload: payload, oldPassword: oldPassword, newPassword: newPassword), default: ())
    }

    func setUpTOTP(_ payload: Data) async throws -> AuthClientTOTPSetupDetails {
        let username = FakePayload.decode(payload)?.username ?? "unknown"
        return try await recordAccountOperation(.setUpTOTP(payload: payload), default: AuthClientTOTPSetupDetails(sharedSecret: "SECRET", username: username))
    }

    func verifyTOTPSetup(_ payload: Data, code: String, friendlyDeviceName: String?) async throws {
        try await recordAccountOperation(.verifyTOTPSetup(payload: payload, code: code, friendlyDeviceName: friendlyDeviceName), default: ())
    }

    func fetchMFAPreference(_ payload: Data) async throws -> AuthClientUserMFAPreference {
        try await recordAccountOperation(.fetchMFAPreference(payload: payload), default: AuthClientUserMFAPreference(enabled: nil, preferred: nil))
    }

    func updateMFAPreference(
        _ payload: Data,
        sms: AuthClientMFAPreference?,
        totp: AuthClientMFAPreference?,
        email: AuthClientMFAPreference?
    ) async throws {
        try await recordAccountOperation(.updateMFAPreference(payload: payload, sms: sms, totp: totp, email: email), default: ())
    }

    func fetchDevices(_ payload: Data) async throws -> [AuthClientDevice] {
        try await recordAccountOperation(.fetchDevices(payload: payload), default: [AuthClientDevice(id: "device-1", name: "iPhone")])
    }

    func rememberDevice(_ payload: Data) async throws {
        try await recordAccountOperation(.rememberDevice(payload: payload), default: ())
    }

    func forgetDevice(_ payload: Data, deviceId: String?) async throws {
        try await recordAccountOperation(.forgetDevice(payload: payload, deviceId: deviceId), default: ())
    }

    func federateToIdentityPool(_ request: EngineFederationRequest, current: Data?) async throws -> Data {
        try await recordAccountOperation(
            .federateToIdentityPool(request, current: current),
            default: FakePayload.federated().data
        )
    }

    /// Records the call and runs its script (Cognito's `StartWebAuthnRegistration`, which may throw before any
    /// sheet), then runs the ceremony where the live engine does: through `context.ceremony`, the sheet lease.
    func associateWebAuthnCredential(_ payload: Data, context: EngineCeremonyContext) async throws {
        try await recordAccountOperation(.associateWebAuthnCredential(payload: payload, anchor: context.anchor), default: ())
        _ = try await runCeremony(context, anchor: context.anchor)
    }

    func listWebAuthnCredentials(_ payload: Data, pageSize: Int, nextToken: String?) async throws -> EngineWebAuthnCredentialPage {
        try await recordAccountOperation(
            .listWebAuthnCredentials(payload: payload, pageSize: pageSize, nextToken: nextToken),
            default: EngineWebAuthnCredentialPage(credentials: [], nextToken: nil)
        )
    }

    func deleteWebAuthnCredential(_ payload: Data, credentialId: String) async throws {
        try await recordAccountOperation(.deleteWebAuthnCredential(payload: payload, credentialId: credentialId), default: ())
    }
}
