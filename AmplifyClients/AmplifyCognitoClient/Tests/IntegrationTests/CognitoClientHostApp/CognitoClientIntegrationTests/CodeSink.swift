//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

// Shared with CognitoClientUITests (the hosted-UI UI tests), which compiles this file and the five other
// shared sandbox helpers (IntegrationTestEnvironment, SandboxPools, SandboxSignUp, SandboxUserCleanup,
// CodeSink, TOTP) and nothing else from this folder. Keep it self-contained: it may use only those files,
// AmplifyCognitoClient, AWSCognitoIdentityProvider, Foundation, Security, CryptoKit and XCTest.

import Foundation

/// Reads the confirmation, MFA and OTP codes Cognito generated for a user on a parity pool (P-5c).
///
/// This is the plugin's integration-backend mechanism, read without `AWSAPIPlugin`: the pools' custom
/// email and SMS sender Lambda decrypts each code and publishes it with the `createMfaInfo` mutation to
/// an AppSync API backed by DynamoDB; nothing is ever delivered. The plugin's tests subscribe to
/// `onCreateMfaInfo`; this helper polls `listMfaInfo(username:)` over plain HTTPS with the API key from
/// `users.json`. Usernames are lower-cased on both sides, as the plugin does. The key never appears in
/// an error or a description.
struct CodeSink: Sendable {
    let endpoint: URL
    let apiKey: SandboxSecret

    init() throws {
        guard let parity = try IntegrationTestEnvironment.state().parity,
              let endpoint = URL(string: parity.codeSinkUrl) else {
            throw HarnessError.malformedFixture("""
            state.json has no parity.codeSinkUrl. Run infra/provision.sh (it runs infra/parity.py), then rebuild.
            """)
        }
        self.endpoint = endpoint
        self.apiKey = try IntegrationTestEnvironment.users().codeSinkAPIKey
    }

    /// The newest unexpired code for `username` stored at or after `since`, polled once a second for up
    /// to `timeout` seconds. `since` is taken a few seconds early to allow for clock skew.
    func code(for username: String, since: Date, timeout: TimeInterval = CodeSink.defaultTimeout) async throws -> String {
        try await code(for: username, since: since, timeout: timeout, describing: "a code for the user")
    }

    /// The default wait for a code. The plugin's `otp(for:)` waits 30 seconds too.
    static let defaultTimeout: TimeInterval = 30

    private func code(for username: String, since: Date, timeout: TimeInterval, describing what: String) async throws -> String {
        let deadline = Date().addingTimeInterval(timeout)
        repeat {
            if let code = try await newestCode(for: username, since: since.addingTimeInterval(-5)) {
                return code
            }
            try await Task.sleep(nanoseconds: 1_000_000_000)
        } while Date() < deadline
        throw HarnessError.timedOut("\(what) in the code sink")
    }

    /// Every stored code for `username`, newest first. One HTTPS request.
    func codes(for username: String) async throws -> [Entry] {
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "content-type")
        request.setValue(apiKey.value, forHTTPHeaderField: "x-api-key")
        request.httpBody = try JSONSerialization.data(withJSONObject: [
            "query": Self.query,
            "variables": ["username": username.lowercased()]
        ])
        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch let error as URLError {
            // A URLError's description carries the endpoint URL, which names the API: report only the code.
            throw HarnessError.malformedFixture("The code sink request failed: URLError \(error.code.rawValue).")
        } catch {
            throw HarnessError.malformedFixture("The code sink request failed.")
        }
        let status = (response as? HTTPURLResponse)?.statusCode ?? 0
        guard status == 200,
              let body = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw HarnessError.malformedFixture("The code sink answered HTTP \(status).")
        }
        if let errors = body["errors"] as? [[String: Any]], !errors.isEmpty {
            let types = errors.compactMap { $0["errorType"] as? String }
            throw HarnessError.malformedFixture("The code sink returned \(errors.count) errors: \(types).")
        }
        let rows = ((body["data"] as? [String: Any])?["listMfaInfo"] as? [[String: Any]]) ?? []
        return rows.compactMap(Entry.init).sorted { $0.createdAt > $1.createdAt }
    }

    struct Entry: Sendable {
        let code: String
        let createdAt: Date
        let expiresAt: Date

        /// Identifies one stored code: the same code sent twice is two entries.
        var fingerprint: String {
            "\(code)@\(createdAt.timeIntervalSince1970)"
        }

        init?(_ row: [String: Any]) {
            guard let code = row["code"] as? String,
                  let created = (row["createdAt"] as? String).flatMap(CodeSink.parseTimestamp),
                  let expiration = row["expirationTime"] as? Double else {
                return nil
            }
            self.code = code
            self.createdAt = created
            self.expiresAt = Date(timeIntervalSince1970: expiration)
        }
    }

    // MARK: - Fresh users

    /// What a code is for. The sink stores only the username and the code, so the kind names the wait
    /// in a timeout; the custom sender captures every one of them (every trigger source but
    /// `AdminCreateUser` and `AccountTakeOverNotification`).
    enum Kind: String, Sendable {
        /// `SignUp` (for a `ccit-confirm-…` user) and `ResendConfirmationCode`.
        case signUp = "sign-up"
        /// `ForgotPassword`.
        case resetPassword = "reset-password"
        /// `UpdateUserAttributes` of a verifiable attribute, and `GetUserAttributeVerificationCode`.
        case attributeVerification = "attribute-verification"
        /// `EMAIL_OTP` or `SMS_MFA` as a second factor, including email MFA setup during sign-in.
        case mfa = "MFA"
        /// `EMAIL_OTP` or `SMS_OTP` as a first factor (`USER_AUTH`).
        case otp = "OTP"
    }

    /// The newest unexpired `kind` code for a fresh user, stored at or after `since` (take it just before
    /// the call that makes Cognito send the code). Polls once a second for up to `timeout` seconds. On
    /// `email-alias` it looks the code up by Cognito's generated username. A timeout names the kind and
    /// the user's pool, never a username.
    ///
    /// `since` allows 5 seconds of clock skew, so a code the same user was sent just before can come back
    /// instead. For a user's first code that cannot happen; for any later one use
    /// `code(for:_:sentBy:)` or `snapshot(for:)`.
    func code(
        for user: FreshUser,
        _ kind: Kind,
        since: Date,
        timeout: TimeInterval = CodeSink.defaultTimeout
    ) async throws -> String {
        try await code(for: user.sinkUsername, since: since, timeout: timeout, describing: "a \(kind.rawValue) code for a fresh user on \(user.pool)")
    }

    /// Runs `action`, which makes Cognito send a `kind` code to `user`, and returns its result with the
    /// first code stored after the action started that was not in the sink before it.
    ///
    /// Unlike `since`, this tells a resent code from the one before it even within the clock-skew
    /// allowance, so it suits a resend, or a wrong-code-then-right-code flow that asks for a new code.
    func code<Result>(
        for user: FreshUser,
        _ kind: Kind,
        timeout: TimeInterval = CodeSink.defaultTimeout,
        sentBy action: () async throws -> Result
    ) async throws -> (result: Result, code: String) {
        let before = try await snapshot(for: user)
        let result = try await action()
        return try await (result, code(for: user, kind, after: before, timeout: timeout))
    }

    /// The codes stored for a user at one moment, to tell the codes sent after it from those before.
    struct Snapshot: Sendable {
        fileprivate let fingerprints: Set<String>
    }

    /// What the sink holds for `user` now. Take it before the call that sends a code, then wait with
    /// `code(for:_:after:timeout:)`.
    func snapshot(for user: FreshUser) async throws -> Snapshot {
        try await Snapshot(fingerprints: Set(codes(for: user.sinkUsername).map(\.fingerprint)))
    }

    /// The newest unexpired `kind` code for `user` that was not in `snapshot`, polled once a second for
    /// up to `timeout` seconds.
    func code(
        for user: FreshUser,
        _ kind: Kind,
        after snapshot: Snapshot,
        timeout: TimeInterval = CodeSink.defaultTimeout
    ) async throws -> String {
        let deadline = Date().addingTimeInterval(timeout)
        repeat {
            let now = Date()
            if let entry = try await codes(for: user.sinkUsername).first(where: {
                !snapshot.fingerprints.contains($0.fingerprint) && $0.expiresAt > now
            }) {
                return entry.code
            }
            try await Task.sleep(nanoseconds: 1_000_000_000)
        } while Date() < deadline
        throw HarnessError.timedOut("a new \(kind.rawValue) code for a fresh user on \(user.pool) in the code sink")
    }

    /// A sign-up (or resent sign-up) code. See `code(for:_:since:timeout:)`.
    func signUpCode(for user: FreshUser, since: Date, timeout: TimeInterval = CodeSink.defaultTimeout) async throws -> String {
        try await code(for: user, .signUp, since: since, timeout: timeout)
    }

    /// A `ForgotPassword` code. See `code(for:_:since:timeout:)`.
    func resetPasswordCode(for user: FreshUser, since: Date, timeout: TimeInterval = CodeSink.defaultTimeout) async throws -> String {
        try await code(for: user, .resetPassword, since: since, timeout: timeout)
    }

    /// An attribute verification code. See `code(for:_:since:timeout:)`.
    func attributeVerificationCode(
        for user: FreshUser,
        since: Date,
        timeout: TimeInterval = CodeSink.defaultTimeout
    ) async throws -> String {
        try await code(for: user, .attributeVerification, since: since, timeout: timeout)
    }

    /// An email or SMS MFA code. See `code(for:_:since:timeout:)`.
    func mfaCode(for user: FreshUser, since: Date, timeout: TimeInterval = CodeSink.defaultTimeout) async throws -> String {
        try await code(for: user, .mfa, since: since, timeout: timeout)
    }

    /// An `EMAIL_OTP` or `SMS_OTP` first-factor code. See `code(for:_:since:timeout:)`.
    func otpCode(for user: FreshUser, since: Date, timeout: TimeInterval = CodeSink.defaultTimeout) async throws -> String {
        try await code(for: user, .otp, since: since, timeout: timeout)
    }

    // MARK: - Private

    private static let query = """
    query ListMfaInfo($username: String!) {
        listMfaInfo(username: $username) { username code expirationTime createdAt }
    }
    """

    private func newestCode(for username: String, since: Date) async throws -> String? {
        let now = Date()
        return try await codes(for: username).first { $0.createdAt >= since && $0.expiresAt > now }?.code
    }

    private static func parseTimestamp(_ text: String) -> Date? {
        let withFraction = ISO8601DateFormatter()
        withFraction.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return withFraction.date(from: text) ?? ISO8601DateFormatter().date(from: text)
    }
}
