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

/// Reads the confirmation, MFA and OTP codes Cognito generated for a user, from the role's `data` API.
///
/// This is the plugin's integration-backend mechanism (`AWSAuthBaseTest.subscribeToOTPCreation` and
/// `listMfaInfo`), read without `AWSAPIPlugin`: the backend's custom email and SMS senders publish each
/// code with the `createMfaInfo` mutation to an AppSync API, which each outputs file names in its `data`
/// block (URL and API key); nothing is ever delivered. As the plugin does, the harness subscribes to
/// `onCreateMfaInfo` (AppSync's real-time WebSocket protocol, over `URLSessionWebSocketTask`) before a user
/// can be sent a code, and also queries `listMfaInfo`, in both forms a backend may have: the sandbox's
/// `listMfaInfo(username:)`, whose items carry a server-set `createdAt`, and the plugin backends'
/// argument-less one. Usernames are compared lower-cased, as the plugin does. The key never appears in an
/// error or a description.
///
/// Each role's codes are read through its own file's API (`FreshUser.pool`): on CI every backend has its
/// own. A role whose file has no `data` block fails the wait that needs a code, with a message naming the
/// file; nothing else needs the block.
struct CodeSink: Sendable {

    init() throws {}

    /// Starts listening for `pool`'s codes, if its outputs have a `data` block, and returns once the
    /// subscription is acknowledged (or could not be; the query still works then). Call it before the
    /// request that makes Cognito send the first code: the subscription only sees codes created after it.
    /// `SandboxSignUp` calls it before every sign-up.
    static func prepare(_ pool: SandboxPool) async {
        guard let api = try? IntegrationTestEnvironment.codeSinkAPI(pool) else {
            return
        }
        await CodeFeed.shared.subscribe(api)
    }

    /// The default wait for a code. The plugin's `otp(for:)` waits 60 seconds: delivery through the
    /// senders can take longer than 30.
    static let defaultTimeout: TimeInterval = 60

    /// The newest unexpired code for `username` on `pool` seen at or after `since`, polled once a second
    /// for up to `timeout` seconds. `since` is taken a few seconds early to allow for clock skew.
    func code(
        for username: String,
        on pool: SandboxPool,
        since: Date,
        timeout: TimeInterval = CodeSink.defaultTimeout
    ) async throws -> String {
        try await code(for: username, on: pool, since: since, timeout: timeout, describing: "a code for the user on \(pool.rawValue)")
    }

    private func code(
        for username: String,
        on pool: SandboxPool,
        since: Date,
        timeout: TimeInterval,
        describing what: String
    ) async throws -> String {
        let api = try IntegrationTestEnvironment.codeSinkAPI(pool)
        await CodeFeed.shared.subscribe(api)
        let deadline = Date().addingTimeInterval(timeout)
        let earliest = since.addingTimeInterval(-5)
        repeat {
            let now = Date()
            if let entry = try await codes(for: username, api: api).first(where: { $0.seenAt >= earliest && $0.expiresAt > now }) {
                return entry.code
            }
            try await Task.sleep(nanoseconds: 1_000_000_000)
        } while Date() < deadline
        throw HarnessError.timedOut("\(what) from the code API (\(await CodeFeed.shared.diagnostics(api)))")
    }

    /// Every code seen for `username` through `api`, newest first: the subscription's, merged with one
    /// `listMfaInfo` query.
    private func codes(for username: String, api: CodeSinkAPI) async throws -> [Entry] {
        await CodeFeed.shared.query(api, username: username.lowercased())
        return await CodeFeed.shared.entries(api, username: username.lowercased())
    }

    /// One code seen for a user.
    struct Entry: Sendable {
        let code: String
        /// When the backend stored it (`createdAt`, where its items carry one), else when this process first
        /// saw it.
        let seenAt: Date
        let expiresAt: Date

        /// Identifies one stored code: the same code sent twice is two entries.
        var fingerprint: String {
            "\(code)@\(expiresAt.timeIntervalSince1970)"
        }
    }

    // MARK: - Fresh users

    /// What a code is for. The API stores only the username and the code, so the kind names the wait
    /// in a timeout; the custom senders capture every one of them (every trigger source but
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

    /// The newest unexpired `kind` code for a fresh user, seen at or after `since` (take it just before
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
        try await code(
            for: user.sinkUsername,
            on: user.pool,
            since: since,
            timeout: timeout,
            describing: "a \(kind.rawValue) code for a fresh user on \(user.pool.rawValue)"
        )
    }

    /// Runs `action`, which makes Cognito send a `kind` code to `user`, and returns its result with the
    /// first code seen after the action started that was not seen before it.
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

    /// The codes seen for a user at one moment, to tell the codes sent after it from those before.
    struct Snapshot: Sendable {
        fileprivate let fingerprints: Set<String>
    }

    /// What has been seen for `user` now. Take it before the call that sends a code, then wait with
    /// `code(for:_:after:timeout:)`. A role whose outputs have no `data` block has nothing to see: the
    /// snapshot is empty, and only a wait for a code fails.
    func snapshot(for user: FreshUser) async throws -> Snapshot {
        guard let api = try? IntegrationTestEnvironment.codeSinkAPI(user.pool) else {
            return Snapshot(fingerprints: [])
        }
        await CodeFeed.shared.subscribe(api)
        return try await Snapshot(fingerprints: Set(codes(for: user.sinkUsername, api: api).map(\.fingerprint)))
    }

    /// The newest unexpired `kind` code for `user` that was not in `snapshot`, polled once a second for
    /// up to `timeout` seconds.
    func code(
        for user: FreshUser,
        _ kind: Kind,
        after snapshot: Snapshot,
        timeout: TimeInterval = CodeSink.defaultTimeout
    ) async throws -> String {
        let api = try IntegrationTestEnvironment.codeSinkAPI(user.pool)
        await CodeFeed.shared.subscribe(api)
        let deadline = Date().addingTimeInterval(timeout)
        repeat {
            let now = Date()
            if let entry = try await codes(for: user.sinkUsername, api: api).first(where: {
                !snapshot.fingerprints.contains($0.fingerprint) && $0.expiresAt > now
            }) {
                return entry.code
            }
            try await Task.sleep(nanoseconds: 1_000_000_000)
        } while Date() < deadline
        throw HarnessError.timedOut("""
        a new \(kind.rawValue) code for a fresh user on \(user.pool.rawValue) from the code API \
        (\(await CodeFeed.shared.diagnostics(api)))
        """)
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
}

/// Every code this process has seen, per API and user, from the subscriptions and the queries.
private actor CodeFeed {

    static let shared = CodeFeed()

    /// Per API URL: per lower-cased username: per fingerprint, the entry first seen.
    private var seen: [URL: [String: [String: CodeSink.Entry]]] = [:]
    private var subscriptions: [URL: CodeSubscription] = [:]
    /// Which `listMfaInfo` form each API answered: `true` for the sandbox's `listMfaInfo(username:)`.
    private var takesUsername: [URL: Bool] = [:]
    /// The APIs that refused both forms: their codes come from the subscription alone.
    private var queryRefused: Set<URL> = []
    /// `COGNITO_CLIENT_INTEG_CODES_FROM=subscription` in the test process's environment (with `xcodebuild`,
    /// `TEST_RUNNER_COGNITO_CLIENT_INTEG_CODES_FROM`): no query at all, as against a backend whose
    /// `listMfaInfo` cannot answer, so a local run proves the subscription alone delivers every code.
    private static let subscriptionOnly = ProcessInfo.processInfo.environment["COGNITO_CLIENT_INTEG_CODES_FROM"] == "subscription"
    /// What happened, for a timeout's message. Never a code, key, URL or username.
    private var events: [URL: [String]] = [:]

    func subscribe(_ api: CodeSinkAPI) async {
        let subscription: CodeSubscription
        if let existing = subscriptions[api.url] {
            subscription = existing
        } else {
            subscription = CodeSubscription(api: api) { [weak self] username, code, expiration in
                await self?.record(api.url, username: username, code: code, expiration: expiration, createdAt: nil)
            } note: { [weak self] event in
                await self?.note(api.url, event)
            }
            subscriptions[api.url] = subscription
        }
        await subscription.ensureConnected()
    }

    func entries(_ api: CodeSinkAPI, username: String) -> [CodeSink.Entry] {
        (seen[api.url]?[username].map { Array($0.values) } ?? []).sorted {
            ($0.seenAt, $0.expiresAt) > ($1.seenAt, $1.expiresAt)
        }
    }

    /// One `listMfaInfo` query, merged into what has been seen. The sandbox's form first; a backend that
    /// refuses it (the plugin's schema has no argument) is asked the argument-less form from then on, and
    /// one that refuses both is not queried again. A failing query is noted, not thrown: the subscription
    /// may still deliver the code.
    func query(_ api: CodeSinkAPI, username: String) async {
        guard !queryRefused.contains(api.url), !Self.subscriptionOnly else {
            return
        }
        let forms = takesUsername[api.url].map { [$0] } ?? [true, false]
        for withUsername in forms {
            do {
                let rows = try await Self.listMfaInfo(api, username: withUsername ? username : nil)
                takesUsername[api.url] = withUsername
                for row in rows {
                    guard let rowUser = (row["username"] as? String)?.lowercased(), rowUser == username,
                          let code = row["code"] as? String,
                          let expiration = (row["expirationTime"] as? NSNumber)?.doubleValue else {
                        continue
                    }
                    let createdAt = (row["createdAt"] as? String).flatMap(Self.parseTimestamp)
                    record(api.url, username: rowUser, code: code, expiration: expiration, createdAt: createdAt)
                }
                return
            } catch let error as QueryRefused {
                note(api.url, "listMfaInfo\(withUsername ? "(username:)" : "") refused: \(error.reason)")
            } catch {
                note(api.url, "listMfaInfo failed: \(error)")
                return
            }
        }
        if takesUsername[api.url] == nil {
            queryRefused.insert(api.url)
        }
    }

    private func record(_ url: URL, username: String, code: String, expiration: Double, createdAt: Date?) {
        let entry = CodeSink.Entry(
            code: code,
            seenAt: createdAt ?? Date(),
            expiresAt: Date(timeIntervalSince1970: expiration)
        )
        let user = username.lowercased()
        if seen[url, default: [:]][user, default: [:]][entry.fingerprint] == nil {
            seen[url, default: [:]][user, default: [:]][entry.fingerprint] = entry
        }
    }

    private func note(_ url: URL, _ event: String) {
        events[url, default: []].append(event)
        if Self.subscriptionOnly {
            // What the switch changed shows in the run's log. Events never name a code, key, URL or user.
            print("[CodeSink] subscription only: \(event)")
        }
    }

    func diagnostics(_ api: CodeSinkAPI) -> String {
        let recent = (events[api.url] ?? []).suffix(6)
        return recent.isEmpty ? "no subscription or query events" : recent.joined(separator: "; ")
    }

    /// A query the API refused, by its error types only.
    struct QueryRefused: Error {
        let reason: String
    }

    private static func listMfaInfo(_ api: CodeSinkAPI, username: String?) async throws -> [[String: Any]] {
        var request = URLRequest(url: api.url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "content-type")
        request.setValue(api.apiKey.value, forHTTPHeaderField: "x-api-key")
        var body: [String: Any] = [:]
        if let username {
            body["query"] = """
            query ListMfaInfo($username: String!) {
                listMfaInfo(username: $username) { username code expirationTime createdAt }
            }
            """
            body["variables"] = ["username": username]
        } else {
            body["query"] = "query ListMfaInfo { listMfaInfo { username code expirationTime } }"
        }
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch let error as URLError {
            // A URLError's description carries the endpoint URL, which names the API: report only the code.
            throw HarnessError.malformedFixture("The code API request failed: URLError \(error.code.rawValue).")
        } catch {
            throw HarnessError.malformedFixture("The code API request failed.")
        }
        let status = (response as? HTTPURLResponse)?.statusCode ?? 0
        let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
        if let errors = json?["errors"] as? [[String: Any]], !errors.isEmpty {
            throw QueryRefused(reason: "\(errors.count) errors \(errors.compactMap { $0["errorType"] as? String })")
        }
        guard status == 200, let json else {
            throw QueryRefused(reason: "HTTP \(status)")
        }
        return ((json["data"] as? [String: Any])?["listMfaInfo"] as? [[String: Any]]) ?? []
    }

    private static func parseTimestamp(_ text: String) -> Date? {
        let withFraction = ISO8601DateFormatter()
        withFraction.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return withFraction.date(from: text) ?? ISO8601DateFormatter().date(from: text)
    }
}

/// One `onCreateMfaInfo` subscription over AppSync's real-time WebSocket protocol (`graphql-ws`), with the
/// API key: what `AWSAPIPlugin` does for the plugin's `subscribeToOTPCreation`. It reconnects when asked
/// after the socket closed.
private actor CodeSubscription {

    typealias Receive = @Sendable (_ username: String, _ code: String, _ expiration: Double) async -> Void
    typealias Note = @Sendable (String) async -> Void

    private let api: CodeSinkAPI
    private let receive: Receive
    private let note: Note
    private var socket: URLSessionWebSocketTask?
    private var connected = false
    private var connecting: Task<Void, Never>?

    init(api: CodeSinkAPI, receive: @escaping Receive, note: @escaping Note) {
        self.api = api
        self.receive = receive
        self.note = note
    }

    /// Returns once the subscription is acknowledged, or once connecting failed or took over 20 seconds.
    func ensureConnected() async {
        if connected {
            return
        }
        if let connecting {
            await connecting.value
            return
        }
        let task = Task { await self.connect() }
        connecting = task
        await task.value
        connecting = nil
    }

    private func connect() async {
        guard let host = api.url.host, let url = Self.realtimeURL(for: api) else {
            await note("no real-time endpoint for the API")
            return
        }
        let socket = URLSession.shared.webSocketTask(with: url, protocols: ["graphql-ws"])
        socket.resume()
        self.socket = socket
        do {
            try await send(["type": "connection_init"], on: socket)
            try await awaitMessage("connection_ack", on: socket)
            let subscriptionId = UUID().uuidString.lowercased()
            let request = try String(
                data: JSONSerialization.data(withJSONObject: [
                    "query": "subscription OnCreateMfaInfo { onCreateMfaInfo { username code expirationTime } }",
                    "variables": [String: String]()
                ]),
                encoding: .utf8
            ) ?? "{}"
            try await send([
                "id": subscriptionId,
                "type": "start",
                "payload": [
                    "data": request,
                    "extensions": ["authorization": ["host": host, "x-api-key": api.apiKey.value]]
                ]
            ], on: socket)
            try await awaitMessage("start_ack", on: socket)
        } catch {
            await note("subscription not connected: \(Self.describe(error))")
            socket.cancel(with: .goingAway, reason: nil)
            self.socket = nil
            return
        }
        connected = true
        await note("subscription connected")
        Task { await self.listen(on: socket) }
        // As the plugin's helper does: the acknowledgement can precede AppSync fanning events out to the
        // new subscription, so give it a moment before the caller makes Cognito send a code.
        try? await Task.sleep(nanoseconds: 2_000_000_000)
    }

    private func listen(on socket: URLSessionWebSocketTask) async {
        while true {
            do {
                let message = try await socket.receive()
                guard let object = Self.object(message) else {
                    continue
                }
                switch object["type"] as? String {
                case "data":
                    let payload = (object["payload"] as? [String: Any])?["data"] as? [String: Any]
                    if let info = payload?["onCreateMfaInfo"] as? [String: Any],
                       let username = info["username"] as? String,
                       let code = info["code"] as? String,
                       let expiration = (info["expirationTime"] as? NSNumber)?.doubleValue {
                        await receive(username, code, expiration)
                    }
                case "error", "complete", "connection_error":
                    await note("subscription ended: \(object["type"] as? String ?? "?")")
                    disconnected(socket)
                    return
                default:
                    continue
                }
            } catch {
                await note("subscription closed: \(Self.describe(error))")
                disconnected(socket)
                return
            }
        }
    }

    private func disconnected(_ closed: URLSessionWebSocketTask) {
        guard socket === closed else {
            return
        }
        connected = false
        socket = nil
        closed.cancel(with: .goingAway, reason: nil)
    }

    private func send(_ object: [String: Any], on socket: URLSessionWebSocketTask) async throws {
        let data = try JSONSerialization.data(withJSONObject: object)
        try await socket.send(.string(String(data: data, encoding: .utf8) ?? "{}"))
    }

    /// Waits for a message of `type`, skipping keep-alives, for up to 10 seconds: past that the socket is
    /// cancelled, which ends the pending receive with an error.
    private func awaitMessage(_ type: String, on socket: URLSessionWebSocketTask) async throws {
        let watchdog = Task {
            try? await Task.sleep(nanoseconds: 10_000_000_000)
            if !Task.isCancelled {
                socket.cancel(with: .goingAway, reason: nil)
            }
        }
        defer { watchdog.cancel() }
        while true {
            let message = try await socket.receive()
            guard let object = Self.object(message) else {
                continue
            }
            let received = object["type"] as? String
            if received == type {
                return
            }
            if received == "ka" {
                continue
            }
            throw HarnessError.malformedFixture("expected \(type), got \(received ?? "?")")
        }
    }

    private static func object(_ message: URLSessionWebSocketTask.Message) -> [String: Any]? {
        let data: Data?
        switch message {
        case .string(let text): data = text.data(using: .utf8)
        case .data(let bytes): data = bytes
        @unknown default: data = nil
        }
        return data.flatMap { try? JSONSerialization.jsonObject(with: $0) as? [String: Any] }
    }

    /// `wss://<id>.appsync-realtime-api.<region>.amazonaws.com/graphql` for a standard AppSync endpoint,
    /// `wss://<domain>/graphql/realtime` for a custom domain, with the API key's authorization header and
    /// an empty payload in the query, base64-encoded as AppSync requires.
    private static func realtimeURL(for api: CodeSinkAPI) -> URL? {
        guard let host = api.url.host else {
            return nil
        }
        let header = try? JSONSerialization.data(withJSONObject: ["host": host, "x-api-key": api.apiKey.value])
        guard let encodedHeader = header?.base64EncodedString()
            .addingPercentEncoding(withAllowedCharacters: .alphanumerics) else {
            return nil
        }
        var components = URLComponents()
        components.scheme = "wss"
        if host.contains("appsync-api") {
            components.host = host.replacingOccurrences(of: "appsync-api", with: "appsync-realtime-api")
            components.path = "/graphql"
        } else {
            components.host = host
            components.path = "/graphql/realtime"
        }
        components.percentEncodedQuery = "header=\(encodedHeader)&payload=e30%3D"
        return components.url
    }

    /// An error by type and code only: a URLError's description carries the URL.
    private static func describe(_ error: Error) -> String {
        if let error = error as? URLError {
            return "URLError \(error.code.rawValue)"
        }
        if let error = error as? HarnessError {
            return error.description
        }
        return String(describing: type(of: error))
    }
}
