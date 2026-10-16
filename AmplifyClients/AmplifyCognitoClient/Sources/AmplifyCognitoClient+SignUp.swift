//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// Sign-up, with the plugin's semantics, per session.
///
/// Sign-up acts on a username, not on the session's user, so it runs whether or not this session is
/// signed in. What it leaves behind for `autoSignIn()` belongs to this session only: another session's
/// `autoSignIn()` never sees it.
///
/// Each call validates its arguments first, with the plugin's messages, and sends nothing when they are
/// empty. `signUp`, `confirmSignUp` and `resendSignUpCode` read no saved record, so none of them throws
/// `storageUnavailable`; `autoSignIn()` is a sign-in, which restores and commits the session's record.
@_spi(AmplifyExperimental)
public extension AmplifyCognitoClient {

    /// Registers a user in the user pool.
    ///
    /// - Parameters:
    ///   - username: The username to register.
    ///   - password: The password, or `nil` for a passwordless user.
    ///   - options: User attributes, validation data and client metadata.
    /// - Returns: `.confirmUser` when the user must confirm a code; `.completeAutoSignIn` when
    ///   `autoSignIn()` can sign them in to this session; otherwise `.done`.
    /// - Throws: `AuthClientError.validation` for an empty username; `.configuration` without a user pool;
    ///   `.service` as Cognito answers, such as `.usernameExists` or `.invalidPassword`; `.notAuthorized` when
    ///   the user pool refuses the request (sign-up disabled for the app client, for example); `.unknown` for a
    ///   failure the client does not recognise; `CancellationError` if the calling task is cancelled.
    func signUp(
        username: String,
        password: String? = nil,
        options: AuthClientSignUpOptions = AuthClientSignUpOptions()
    ) async throws -> AuthClientSignUpResult {
        try Self.requireSignUpArgument(username, SignUpValidation.signUpUsername)
        let request = EngineSignUpRequest(
            username: username,
            password: password,
            userAttributes: Self.cognitoAttributes(options.userAttributes),
            validationData: options.validationData,
            clientMetadata: options.clientMetadata
        )
        let core = core
        return try await core.userPoolOperation("sign up") { engine in
            try await engine.signUp(request)
        }
    }

    /// Confirms a sign-up with the code Cognito sent.
    ///
    /// - Returns: `.completeAutoSignIn` when `autoSignIn()` can sign the user in to this session, else `.done`.
    /// - Throws: `AuthClientError.validation` for an empty username or code; `.configuration` without a user
    ///   pool; `.service` as Cognito answers, such as `.codeMismatch` or `.codeExpired`; `.notAuthorized` when
    ///   the user pool refuses the confirmation (a user already confirmed, for example); `.unknown` for a
    ///   failure the client does not recognise; `CancellationError` if the calling task is cancelled.
    func confirmSignUp(
        for username: String,
        confirmationCode: String,
        options: AuthClientConfirmSignUpOptions = AuthClientConfirmSignUpOptions()
    ) async throws -> AuthClientSignUpResult {
        try Self.requireSignUpArgument(username, SignUpValidation.signUpUsername)
        try Self.requireSignUpArgument(confirmationCode, SignUpValidation.confirmationCode)
        let request = EngineConfirmSignUpRequest(
            username: username,
            confirmationCode: confirmationCode,
            clientMetadata: options.clientMetadata,
            forceAliasCreation: options.forceAliasCreation
        )
        let core = core
        return try await core.userPoolOperation("confirm a sign-up") { engine in
            try await engine.confirmSignUp(request)
        }
    }

    /// Sends the sign-up confirmation code again.
    ///
    /// - Returns: Where the code was sent.
    /// - Throws: `AuthClientError.validation` for an empty username; `.configuration` without a user pool;
    ///   `.service` as Cognito answers, such as `.limitExceeded`; `.notAuthorized` when the user pool refuses
    ///   the request; `.unknown` for a failure the client does not recognise, or an answer without delivery
    ///   details; `CancellationError` if the calling task is cancelled.
    func resendSignUpCode(
        for username: String,
        options: AuthClientResendSignUpCodeOptions = AuthClientResendSignUpCodeOptions()
    ) async throws -> AuthClientCodeDeliveryDetails {
        try Self.requireSignUpArgument(username, SignUpValidation.resendUsername)
        let clientMetadata = options.clientMetadata
        let core = core
        return try await core.userPoolOperation("resend a sign-up code") { engine in
            try await engine.resendSignUpCode(username: username, clientMetadata: clientMetadata)
        }
    }

    /// Signs in the user this session's sign-up left ready for it (`.completeAutoSignIn`).
    ///
    /// A sign-in: refused when this session is already signed in, it supersedes a sign-in waiting on a
    /// challenge, and on success the session is signed in and sends `.signedIn`.
    ///
    /// **Keep a handle alive between `confirmSignUp` and `autoSignIn`.** What the sign-up left is held in
    /// memory by the session, which is released with its last handle; a new handle then has nothing to
    /// complete. Only the session's last sign-up or confirmation counts: any later `signUp` or
    /// `confirmSignUp` on this session replaces it, whatever its outcome. It is not cleared by signing in or
    /// out, so a second call reaches Cognito again, which refuses the spent session with `.notAuthorized`.
    ///
    /// - Returns: `.done` once signed in; otherwise the step to present, as `signIn` does.
    /// - Throws: `AuthClientError.invalidState` if this session has no sign-up ready to sign in (checked
    ///   first, so a pending sign-in is kept), or is signed in; otherwise as
    ///   `signIn(username:password:options:)`.
    func autoSignIn() async throws -> AuthClientSignInResult {
        let core = core
        return try await core.autoSignIn()
    }
}

extension AmplifyCognitoClient {

    /// User attributes as Cognito names them; the last value wins for a repeated key.
    static func cognitoAttributes(_ attributes: [AuthClientUserAttribute]) -> [String: String] {
        Dictionary(attributes.map { ($0.key.cognitoName, $0.value) }, uniquingKeysWith: { _, last in last })
    }

    /// Throws `validation` for an empty `value`, before any request is sent.
    static func requireSignUpArgument(_ value: String, _ rule: SignUpValidation) throws {
        guard value.isEmpty else {
            return
        }
        throw AuthClientError.validation(field: rule.field, rule.description, rule.suggestion)
    }
}

/// The plugin's sign-up validation errors, string for string (`AuthPluginErrorConstants`), including the
/// resend's, which names `confirmSignUp`.
struct SignUpValidation: Sendable {
    let field: String
    let description: String
    let suggestion: String

    static let signUpUsername = SignUpValidation(
        field: "username",
        description: "Username is required to signUp",
        suggestion: "Make sure that a valid username is passed for signUp"
    )

    static let confirmationCode = SignUpValidation(
        field: "code",
        description: "code is required to confirmSignUp",
        suggestion: "Make sure that a valid code is passed for confirmSignUp"
    )

    static let resendUsername = SignUpValidation(
        field: "username",
        description: "Username is required to confirmSignUp",
        suggestion: "Make sure that a valid username is passed for confirmSignUp"
    )
}
