//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AWSCognitoIdentityProvider
import Foundation
import InternalAWSCognitoAuth

/// The refresh tokens one operation's sign-in was issued, so a cancel can revoke them.
///
/// A cancel stops the operation's machine, but a Cognito call already in flight still returns: the
/// machine, now signed out, ignores its answer, and the refresh token in it would be orphaned. The tap sees
/// every `InitiateAuth` / `RespondToAuthChallenge` answer first.
///
/// Exactly one party revokes each token. `cancel` only marks the operation.
/// When the cancelled step ends, `settle` revokes every token the tap saw **except** the one the step hands
/// back (as `.done` for the core to revoke, or as a failure's issued tokens, which the engine revokes); from
/// then on, every token it sees is revoked at once. Revocations run best effort, from an unstructured task
/// (a cancelled caller could not send the request), so neither call waits for Cognito.
///
/// Only a cancelled operation's tokens are revoked. The engine cancels a sign-in only for a sign-out, a
/// purge or a deletion (a superseding sign-in finds no step in flight, only a pending challenge, which
/// holds no tokens), and the core refuses to commit, and revokes, whatever such a step returns. The engine
/// also cancels the tap of a step that failed without keeping its attempt: whatever that step was issued (a
/// hosted-UI response the identity check refused) nothing commits.
///
/// - Note: `@unchecked Sendable`: `seen` and `isCancelled` are only touched while holding `lock`.
final class IssuedTokenTap: @unchecked Sendable {

    private let clientId: String?
    private let clientSecret: String?
    private let lock = NSLock()
    private var seen: [String] = []
    private var isCancelled = false
    private var isSettled = false
    private var revocations: [Task<Void, Never>] = []
    private var challengeRejectedByUserPool = false

    init(clientId: String?, clientSecret: String?) {
        self.clientId = clientId
        self.clientSecret = clientSecret
    }

    /// Records a refresh token Cognito issued, or revokes it at once if the operation was cancelled.
    func observe(_ refreshToken: String?, revokingWith userPool: any CognitoUserPoolBehavior) {
        guard let refreshToken else {
            return
        }
        let revokeNow = withLock { () -> Bool in
            if isSettled {
                return true
            }
            seen.append(refreshToken)
            return false
        }
        if revokeNow {
            revoke([refreshToken], with: userPool)
        }
    }

    /// Marks the operation cancelled. Nothing is revoked until `settle`.
    func cancel() {
        withLock { isCancelled = true }
    }

    /// Once a cancelled operation's step has ended: revokes every refresh token the tap saw except
    /// `handedBack`, the one the step returned for someone else to revoke, and revokes every later one at
    /// once. Does nothing for an operation that was never cancelled: its tokens are the session's.
    func settle(handedBack: String?, revokingWith userPool: (any CognitoUserPoolBehavior)?) {
        let tokens = withLock { () -> [String] in
            guard isCancelled, !isSettled else {
                return []
            }
            isSettled = true
            defer { seen = [] }
            return seen.filter { $0 != handedBack }
        }
        if let userPool, !tokens.isEmpty {
            revoke(tokens, with: userPool)
        }
    }

    /// How many refresh tokens the tap has seen and not yet revoked or settled: a mark for
    /// `revokeSeen(since:except:revokingWith:)`.
    var seenCount: Int {
        withLock { seen.count }
    }

    /// Revokes the tokens seen since `mark` (a `seenCount` taken when a step started), except `handedBack`,
    /// and forgets them, leaving the tap open for the operation's next step. For a step that failed but kept
    /// its attempt: whatever it was issued is not committed. Does nothing once the tap is settled.
    func revokeSeen(since mark: Int, except handedBack: String?, revokingWith userPool: (any CognitoUserPoolBehavior)?) {
        let tokens = withLock { () -> [String] in
            guard !isSettled, mark < seen.count else {
                return []
            }
            let stepTokens = seen[mark...].filter { $0 != handedBack }
            seen.removeSubrange(mark...)
            return Array(stepTokens)
        }
        if let userPool, !tokens.isEmpty {
            revoke(tokens, with: userPool)
        }
    }

    /// Whether the operation's latest challenge answer (`RespondToAuthChallenge`, or a TOTP setup's
    /// `AssociateSoftwareToken` / `VerifySoftwareToken`) was rejected with the user pool's
    /// `NotAuthorizedException`: what the confirm path needs, beside the message, to call a failure an
    /// expired challenge (the engine's error keeps no exception underneath).
    var lastChallengeRejectedByUserPool: Bool {
        withLock { challengeRejectedByUserPool }
    }

    /// Records how the latest `RespondToAuthChallenge` ended.
    func recordChallengeAnswer(rejection: Error?) {
        let rejected = rejection is AWSCognitoIdentityProvider.NotAuthorizedException
        withLock { challengeRejectedByUserPool = rejected }
    }

    /// Waits for every revocation the tap started. For tests.
    func revocationsFinished() async {
        for task in withLock({ revocations }) {
            await task.value
        }
    }

    private func revoke(_ tokens: [String], with userPool: any CognitoUserPoolBehavior) {
        guard let clientId else {
            return
        }
        let clientSecret = clientSecret
        let task = Task {
            for token in tokens {
                _ = try? await userPool.revokeToken(input: RevokeTokenInput(
                    clientId: clientId,
                    clientSecret: clientSecret,
                    token: token
                ))
            }
        }
        withLock { revocations.append(task) }
    }

    private func withLock<Value>(_ body: () -> Value) -> Value {
        lock.lock()
        defer { lock.unlock() }
        return body()
    }
}

/// An operation's user pool: the session's, with every sign-in answer shown to the operation's tap first.
struct TappedUserPool: CognitoUserPoolBehavior {

    let base: any CognitoUserPoolBehavior
    let tap: IssuedTokenTap

    func initiateAuth(input: InitiateAuthInput) async throws -> InitiateAuthOutput {
        let output = try await base.initiateAuth(input: input)
        tap.observe(output.authenticationResult?.refreshToken, revokingWith: base)
        return output
    }

    func respondToAuthChallenge(input: RespondToAuthChallengeInput) async throws -> RespondToAuthChallengeOutput {
        let output: RespondToAuthChallengeOutput
        do {
            output = try await base.respondToAuthChallenge(input: input)
        } catch {
            tap.recordChallengeAnswer(rejection: error)
            throw error
        }
        tap.recordChallengeAnswer(rejection: nil)
        tap.observe(output.authenticationResult?.refreshToken, revokingWith: base)
        return output
    }

    func signUp(input: SignUpInput) async throws -> SignUpOutput {
        try await base.signUp(input: input)
    }

    func confirmSignUp(input: ConfirmSignUpInput) async throws -> ConfirmSignUpOutput {
        try await base.confirmSignUp(input: input)
    }

    func globalSignOut(input: GlobalSignOutInput) async throws -> GlobalSignOutOutput {
        try await base.globalSignOut(input: input)
    }

    func revokeToken(input: RevokeTokenInput) async throws -> RevokeTokenOutput {
        try await base.revokeToken(input: input)
    }

    func getTokensFromRefreshToken(input: GetTokensFromRefreshTokenInput) async throws -> GetTokensFromRefreshTokenOutput {
        try await base.getTokensFromRefreshToken(input: input)
    }

    func getUserAttributeVerificationCode(input: GetUserAttributeVerificationCodeInput) async throws -> GetUserAttributeVerificationCodeOutput {
        try await base.getUserAttributeVerificationCode(input: input)
    }

    func getUser(input: GetUserInput) async throws -> GetUserOutput {
        try await base.getUser(input: input)
    }

    func updateUserAttributes(input: UpdateUserAttributesInput) async throws -> UpdateUserAttributesOutput {
        try await base.updateUserAttributes(input: input)
    }

    func verifyUserAttribute(input: AWSCognitoIdentityProvider.VerifyUserAttributeInput) async throws -> AWSCognitoIdentityProvider.VerifyUserAttributeOutput {
        try await base.verifyUserAttribute(input: input)
    }

    func changePassword(input: ChangePasswordInput) async throws -> ChangePasswordOutput {
        try await base.changePassword(input: input)
    }

    func deleteUser(input: DeleteUserInput) async throws -> DeleteUserOutput {
        try await base.deleteUser(input: input)
    }

    func resendConfirmationCode(input: ResendConfirmationCodeInput) async throws -> ResendConfirmationCodeOutput {
        try await base.resendConfirmationCode(input: input)
    }

    func forgotPassword(input: ForgotPasswordInput) async throws -> ForgotPasswordOutput {
        try await base.forgotPassword(input: input)
    }

    func confirmForgotPassword(input: ConfirmForgotPasswordInput) async throws -> ConfirmForgotPasswordOutput {
        try await base.confirmForgotPassword(input: input)
    }

    func listDevices(input: ListDevicesInput) async throws -> ListDevicesOutput {
        try await base.listDevices(input: input)
    }

    func updateDeviceStatus(input: UpdateDeviceStatusInput) async throws -> UpdateDeviceStatusOutput {
        try await base.updateDeviceStatus(input: input)
    }

    func forgetDevice(input: ForgetDeviceInput) async throws -> ForgetDeviceOutput {
        try await base.forgetDevice(input: input)
    }

    func confirmDevice(input: ConfirmDeviceInput) async throws -> ConfirmDeviceOutput {
        try await base.confirmDevice(input: input)
    }

    func associateSoftwareToken(input: AssociateSoftwareTokenInput) async throws -> AssociateSoftwareTokenOutput {
        do {
            let output = try await base.associateSoftwareToken(input: input)
            tap.recordChallengeAnswer(rejection: nil)
            return output
        } catch {
            // A TOTP setup answers its challenge here too: an expired setup session is rejected by this
            // call, not by `RespondToAuthChallenge`.
            tap.recordChallengeAnswer(rejection: error)
            throw error
        }
    }

    func verifySoftwareToken(input: VerifySoftwareTokenInput) async throws -> VerifySoftwareTokenOutput {
        do {
            let output = try await base.verifySoftwareToken(input: input)
            tap.recordChallengeAnswer(rejection: nil)
            return output
        } catch {
            // A TOTP setup answers its challenge here too: an expired setup session is rejected by this
            // call, not by `RespondToAuthChallenge`.
            tap.recordChallengeAnswer(rejection: error)
            throw error
        }
    }

    func setUserMFAPreference(input: SetUserMFAPreferenceInput) async throws -> SetUserMFAPreferenceOutput {
        try await base.setUserMFAPreference(input: input)
    }

    func listWebAuthnCredentials(input: ListWebAuthnCredentialsInput) async throws -> ListWebAuthnCredentialsOutput {
        try await base.listWebAuthnCredentials(input: input)
    }

    func deleteWebAuthnCredential(input: DeleteWebAuthnCredentialInput) async throws -> DeleteWebAuthnCredentialOutput {
        try await base.deleteWebAuthnCredential(input: input)
    }

    func startWebAuthnRegistration(input: StartWebAuthnRegistrationInput) async throws -> StartWebAuthnRegistrationOutput {
        try await base.startWebAuthnRegistration(input: input)
    }

    func completeWebAuthnRegistration(input: CompleteWebAuthnRegistrationInput) async throws -> CompleteWebAuthnRegistrationOutput {
        try await base.completeWebAuthnRegistration(input: input)
    }
}
