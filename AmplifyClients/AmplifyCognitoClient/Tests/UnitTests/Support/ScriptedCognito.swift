//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AWSCognitoIdentity
import AWSCognitoIdentityProvider
import Foundation
import InternalAWSCognitoAuth
import XCTest

/// One recorded Cognito call: the operation's name and its input.
///
/// - Note: `@unchecked Sendable`: the inputs are SDK input structs, which are `Sendable`, held as `Any`.
struct CognitoCall: @unchecked Sendable {
    let operation: String
    let input: Any
}

enum ScriptedCognitoError: Error, Equatable {
    /// The test did not script this operation: a call the test did not expect.
    case notScripted(String)
}

/// The scripted Cognito calls of one test, shared by the user pool and identity doubles: records every call,
/// in order, and answers each from the script for its operation. An operation with no script throws
/// `ScriptedCognitoError.notScripted`, so an unexpected call fails the step that made it.
///
/// - Note: `@unchecked Sendable`: `recorded`, `queued` and `fallbacks` are only touched while holding `lock`.
final class ScriptedCognito: @unchecked Sendable {

    typealias Script = @Sendable (Any) async throws -> Any

    private let lock = NSLock()
    private var recorded: [CognitoCall] = []
    private var queued: [String: [Script]] = [:]
    private var fallbacks: [String: Script] = [:]

    /// Every call, in order.
    var calls: [CognitoCall] {
        withLock { recorded }
    }

    /// The name of every call, in order.
    var operations: [String] {
        calls.map(\.operation)
    }

    /// Fails the test if a one-off answer queued with `once` was never used: the call it scripted never
    /// happened. Call it from `tearDown`.
    func assertConsumed(file: StaticString = #filePath, line: UInt = #line) {
        let unused = withLock { queued.filter { !$0.value.isEmpty }.map { "\($0.key) ×\($0.value.count)" }.sorted() }
        XCTAssertEqual(unused, [], "scripted Cognito answers were never used", file: file, line: line)
    }

    /// Forgets the calls so far; the scripts stay.
    func clearCalls() {
        withLock { recorded = [] }
    }

    /// The inputs of every `operation` call, in order.
    func inputs<Input>(_ operation: String, as type: Input.Type = Input.self) -> [Input] {
        calls.filter { $0.operation == operation }.compactMap { $0.input as? Input }
    }

    /// Answers every `operation` call with `script`, once any answers queued with `once` are used up.
    func always<Input, Output>(
        _ operation: String,
        _ script: @escaping @Sendable (Input) async throws -> Output
    ) {
        withLock { fallbacks[operation] = Self.erase(script) }
    }

    /// Answers the next `operation` call with `script`. Queued answers are used in order, before `always`.
    func once<Input, Output>(
        _ operation: String,
        _ script: @escaping @Sendable (Input) async throws -> Output
    ) {
        withLock { queued[operation, default: []].append(Self.erase(script)) }
    }

    func answer<Input, Output>(_ operation: String, _ input: Input) async throws -> Output {
        let script = withLock { () -> Script? in
            recorded.append(CognitoCall(operation: operation, input: input))
            if var next = queued[operation], !next.isEmpty {
                let first = next.removeFirst()
                queued[operation] = next
                return first
            }
            return fallbacks[operation]
        }
        guard let script else {
            throw ScriptedCognitoError.notScripted(operation)
        }
        guard let output = try await script(input) as? Output else {
            preconditionFailure("The script for \(operation) returned the wrong type")
        }
        return output
    }

    private static func erase<Input, Output>(_ script: @escaping @Sendable (Input) async throws -> Output) -> Script {
        { input in
            guard let input = input as? Input else {
                preconditionFailure("The script's input type does not match the operation's")
            }
            return try await script(input)
        }
    }

    private func withLock<Value>(_ body: () throws -> Value) rethrows -> Value {
        lock.lock()
        defer { lock.unlock() }
        return try body()
    }
}

/// The engine's `CognitoUserPoolBehavior` over a `ScriptedCognito`: the client-side equivalent of the plugin's
/// `MockIdentityProvider`, written without importing plugin test code.
struct ScriptedUserPool: CognitoUserPoolBehavior {

    let cognito: ScriptedCognito

    func initiateAuth(input: InitiateAuthInput) async throws -> InitiateAuthOutput {
        try await cognito.answer("InitiateAuth", input)
    }

    func respondToAuthChallenge(input: RespondToAuthChallengeInput) async throws -> RespondToAuthChallengeOutput {
        try await cognito.answer("RespondToAuthChallenge", input)
    }

    func signUp(input: SignUpInput) async throws -> SignUpOutput {
        try await cognito.answer("SignUp", input)
    }

    func confirmSignUp(input: ConfirmSignUpInput) async throws -> ConfirmSignUpOutput {
        try await cognito.answer("ConfirmSignUp", input)
    }

    func globalSignOut(input: GlobalSignOutInput) async throws -> GlobalSignOutOutput {
        try await cognito.answer("GlobalSignOut", input)
    }

    func revokeToken(input: RevokeTokenInput) async throws -> RevokeTokenOutput {
        try await cognito.answer("RevokeToken", input)
    }

    func getTokensFromRefreshToken(input: GetTokensFromRefreshTokenInput) async throws -> GetTokensFromRefreshTokenOutput {
        try await cognito.answer("GetTokensFromRefreshToken", input)
    }

    func getUserAttributeVerificationCode(
        input: GetUserAttributeVerificationCodeInput
    ) async throws -> GetUserAttributeVerificationCodeOutput {
        try await cognito.answer("GetUserAttributeVerificationCode", input)
    }

    func getUser(input: GetUserInput) async throws -> GetUserOutput {
        try await cognito.answer("GetUser", input)
    }

    func updateUserAttributes(input: UpdateUserAttributesInput) async throws -> UpdateUserAttributesOutput {
        try await cognito.answer("UpdateUserAttributes", input)
    }

    func verifyUserAttribute(
        input: AWSCognitoIdentityProvider.VerifyUserAttributeInput
    ) async throws -> AWSCognitoIdentityProvider.VerifyUserAttributeOutput {
        try await cognito.answer("VerifyUserAttribute", input)
    }

    func changePassword(input: ChangePasswordInput) async throws -> ChangePasswordOutput {
        try await cognito.answer("ChangePassword", input)
    }

    func deleteUser(input: DeleteUserInput) async throws -> DeleteUserOutput {
        try await cognito.answer("DeleteUser", input)
    }

    func resendConfirmationCode(input: ResendConfirmationCodeInput) async throws -> ResendConfirmationCodeOutput {
        try await cognito.answer("ResendConfirmationCode", input)
    }

    func forgotPassword(input: ForgotPasswordInput) async throws -> ForgotPasswordOutput {
        try await cognito.answer("ForgotPassword", input)
    }

    func confirmForgotPassword(input: ConfirmForgotPasswordInput) async throws -> ConfirmForgotPasswordOutput {
        try await cognito.answer("ConfirmForgotPassword", input)
    }

    func listDevices(input: ListDevicesInput) async throws -> ListDevicesOutput {
        try await cognito.answer("ListDevices", input)
    }

    func updateDeviceStatus(input: UpdateDeviceStatusInput) async throws -> UpdateDeviceStatusOutput {
        try await cognito.answer("UpdateDeviceStatus", input)
    }

    func forgetDevice(input: ForgetDeviceInput) async throws -> ForgetDeviceOutput {
        try await cognito.answer("ForgetDevice", input)
    }

    func confirmDevice(input: ConfirmDeviceInput) async throws -> ConfirmDeviceOutput {
        try await cognito.answer("ConfirmDevice", input)
    }

    func associateSoftwareToken(input: AssociateSoftwareTokenInput) async throws -> AssociateSoftwareTokenOutput {
        try await cognito.answer("AssociateSoftwareToken", input)
    }

    func verifySoftwareToken(input: VerifySoftwareTokenInput) async throws -> VerifySoftwareTokenOutput {
        try await cognito.answer("VerifySoftwareToken", input)
    }

    func setUserMFAPreference(input: SetUserMFAPreferenceInput) async throws -> SetUserMFAPreferenceOutput {
        try await cognito.answer("SetUserMFAPreference", input)
    }

    func listWebAuthnCredentials(input: ListWebAuthnCredentialsInput) async throws -> ListWebAuthnCredentialsOutput {
        try await cognito.answer("ListWebAuthnCredentials", input)
    }

    func deleteWebAuthnCredential(input: DeleteWebAuthnCredentialInput) async throws -> DeleteWebAuthnCredentialOutput {
        try await cognito.answer("DeleteWebAuthnCredential", input)
    }

    func startWebAuthnRegistration(input: StartWebAuthnRegistrationInput) async throws -> StartWebAuthnRegistrationOutput {
        try await cognito.answer("StartWebAuthnRegistration", input)
    }

    func completeWebAuthnRegistration(
        input: CompleteWebAuthnRegistrationInput
    ) async throws -> CompleteWebAuthnRegistrationOutput {
        try await cognito.answer("CompleteWebAuthnRegistration", input)
    }
}

/// The engine's `CognitoIdentityBehavior` over a `ScriptedCognito`: the client-side equivalent of the plugin's
/// `MockIdentity`.
struct ScriptedIdentity: CognitoIdentityBehavior, Sendable {

    let cognito: ScriptedCognito

    func getId(input: GetIdInput) async throws -> GetIdOutput {
        try await cognito.answer("GetId", input)
    }

    func getCredentialsForIdentity(input: GetCredentialsForIdentityInput) async throws -> GetCredentialsForIdentityOutput {
        try await cognito.answer("GetCredentialsForIdentity", input)
    }
}
