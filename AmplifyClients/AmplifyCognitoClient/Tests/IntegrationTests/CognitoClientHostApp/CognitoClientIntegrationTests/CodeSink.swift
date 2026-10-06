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
/// can be sent a code (`prepare(_:)`, before every sign-up), and also queries `listMfaInfo`, in both forms a
/// backend may have: the sandbox's `listMfaInfo(username:)`, whose items carry a server-set `createdAt`, and
/// the plugin backends' argument-less one. Every row is matched to the user here, by its username
/// lower-cased, as the plugin does, whatever the form returned.
///
/// The subscription is what a plugin backend relies on: its argument-less `listMfaInfo` resolves a table
/// scan into a list field, so AppSync answers it with a type-mismatch error and no rows
/// (`PasswordlessTests/README.md`), for the plugin's `AWSAuthBaseTest` too. A code sent before the
/// subscription is acknowledged is never seen there, which is why every sign-up prepares it first.
///
/// Until a form has answered, one the API refuses with untyped GraphQL errors only (AppSync's validation
/// and type-mismatch errors, what a schema without that query or argument returns) is not asked again
/// (`ListMfaInfoForms`). A typed GraphQL error (`UnauthorizedException`, a resolver error, throttling, an
/// `InternalFailure`), an HTTP error or a transport error is transient: it is noted, and the form asked
/// again on the next poll. Once a form has answered, only it is asked, whatever fails later. The key never
/// appears in an error or a description.
///
/// Each role's codes are read through its own file's API (`FreshUser.pool`): on CI every backend has its
/// own. A role whose file has no `data` block fails the wait that needs a code, with a message naming the
/// file; nothing else needs the block.
struct CodeSink: Sendable {

    init() throws {}

    /// Starts listening for `pool`'s codes, if its outputs have a `data` block, and returns once the
    /// subscription is acknowledged (or could not be; the query still works then). Call it before the
    /// request that makes Cognito send the first code: the subscription only sees codes created after it,
    /// and on a plugin backend it is the only way to see one. Every sign-up calls it first: `SandboxSignUp`,
    /// the parity checks' raw sign-up, and `ClientSignUpTestCase`'s sign-up through the client.
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
        throw HarnessError.timedOut("\(what) from the code API (\(await CodeFeed.shared.diagnostics(api, requestedAt: since)))")
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
    /// first code sent after the action started: one not seen before it (`code(for:_:after:)`).
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

    /// `code(for:_:sentBy:)` for a user the test signed up by hand, by its username on `pool`.
    func code<Result>(
        for username: String,
        on pool: SandboxPool,
        timeout: TimeInterval = CodeSink.defaultTimeout,
        sentBy action: () async throws -> Result
    ) async throws -> (result: Result, code: String) {
        let before = try await snapshot(for: username, on: pool)
        let result = try await action()
        return try await (result, code(for: username, on: pool, after: before, timeout: timeout))
    }

    /// The codes seen for a user at one moment, to tell the codes sent after it from those before.
    struct Snapshot: Sendable {
        fileprivate let fingerprints: Set<String>
        /// When it was taken: the code it is for is asked for after this, for a timeout's message.
        fileprivate var takenAt = Date()
    }

    /// What has been seen for `user` now. Take it before the call that sends a code, then wait with
    /// `code(for:_:after:timeout:)`. A role whose outputs have no `data` block has nothing to see: the
    /// snapshot is empty, and only a wait for a code fails.
    func snapshot(for user: FreshUser) async throws -> Snapshot {
        try await snapshot(for: user.sinkUsername, on: user.pool)
    }

    /// What has been seen for `username` on `pool` now (`snapshot(for:)`, for a user the test signed up
    /// by hand).
    func snapshot(for username: String, on pool: SandboxPool) async throws -> Snapshot {
        guard let api = try? IntegrationTestEnvironment.codeSinkAPI(pool) else {
            return Snapshot(fingerprints: [])
        }
        await CodeFeed.shared.subscribe(api)
        return try await Snapshot(fingerprints: Set(codes(for: username, api: api).map(\.fingerprint)))
    }

    /// The first unexpired `kind` code for `user` sent after `snapshot`: the first one a poll (once a second,
    /// for up to `timeout` seconds) finds that was not in it. Were two to arrive within one poll, the newer
    /// is returned; a test waits for each code before asking for the next.
    func code(
        for user: FreshUser,
        _ kind: Kind,
        after snapshot: Snapshot,
        timeout: TimeInterval = CodeSink.defaultTimeout
    ) async throws -> String {
        try await code(
            for: user.sinkUsername,
            on: user.pool,
            after: snapshot,
            timeout: timeout,
            describing: "a new \(kind.rawValue) code for a fresh user on \(user.pool.rawValue)"
        )
    }

    /// The first unexpired code for `username` on `pool` sent after `snapshot` (`code(for:_:after:)`, for a
    /// user the test signed up by hand). Unlike `code(for:on:since:)`, it never returns a code sent
    /// before the snapshot, such as the sign-up code of a pool that left the user to confirm.
    func code(
        for username: String,
        on pool: SandboxPool,
        after snapshot: Snapshot,
        timeout: TimeInterval = CodeSink.defaultTimeout
    ) async throws -> String {
        try await code(
            for: username,
            on: pool,
            after: snapshot,
            timeout: timeout,
            describing: "a new code for the user on \(pool.rawValue)"
        )
    }

    private func code(
        for username: String,
        on pool: SandboxPool,
        after snapshot: Snapshot,
        timeout: TimeInterval,
        describing what: String
    ) async throws -> String {
        let api = try IntegrationTestEnvironment.codeSinkAPI(pool)
        await CodeFeed.shared.subscribe(api)
        let deadline = Date().addingTimeInterval(timeout)
        repeat {
            let now = Date()
            if let entry = try await codes(for: username, api: api).first(where: {
                !snapshot.fingerprints.contains($0.fingerprint) && $0.expiresAt > now
            }) {
                return entry.code
            }
            try await Task.sleep(nanoseconds: 1_000_000_000)
        } while Date() < deadline
        throw HarnessError.timedOut("\(what) from the code API (\(await CodeFeed.shared.diagnostics(api, requestedAt: snapshot.takenAt)))")
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
    /// Per API, which `listMfaInfo` forms to ask, from its answers so far.
    private var forms: [URL: ListMfaInfoForms] = [:]
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

    /// One `listMfaInfo` query, merged into what has been seen, asked as the plugin's `queriedOTP(for:)` asks:
    /// the sandbox's form first, then the argument-less one (the plugin backends' schema), until one answers
    /// (`ListMfaInfoForms`). A failing query is noted, not thrown: the subscription may still deliver the
    /// code.
    func query(_ api: CodeSinkAPI, username: String) async {
        guard !Self.subscriptionOnly else {
            return
        }
        for withUsername in forms[api.url, default: ListMfaInfoForms()].toAsk {
            let form = "listMfaInfo\(withUsername ? "(username:)" : "")"
            do {
                let rows = try await Self.listMfaInfo(api, username: withUsername ? username : nil)
                if forms[api.url, default: ListMfaInfoForms()].answering == nil {
                    note(api.url, "\(form) answered")
                }
                forms[api.url, default: ListMfaInfoForms()].answered(withUsername)
                for row in rows {
                    // Matched here, whatever the form: the argument-less one returns every user's rows.
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
                forms[api.url, default: ListMfaInfoForms()].refused(withUsername, byTheSchema: error.byTheSchema)
                note(api.url, "\(form) \(error.byTheSchema ? "refused" : "failed"): \(error.reason)")
            } catch {
                note(api.url, "\(form) failed: \(error)")
            }
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
        // A poll repeats the same failure every second: keep one of a run of equal events.
        guard events[url]?.last != event else {
            return
        }
        events[url, default: []].append(event)
        if Self.subscriptionOnly {
            // What the switch changed shows in the run's log. Events never name a code, key, URL or user.
            print("[CodeSink] subscription only: \(event)")
        }
    }

    /// What happened on `api`, for a timeout's message. With `requestedAt`, when the code was asked for: a
    /// subscription acknowledged only after that cannot have seen the code, which is then said.
    func diagnostics(_ api: CodeSinkAPI, requestedAt: Date? = nil) async -> String {
        var recent = Array((events[api.url] ?? []).suffix(6))
        if let requestedAt, let connectedAt = await subscriptions[api.url]?.connectedAt,
           connectedAt > requestedAt.addingTimeInterval(1) {
            let late = Int(connectedAt.timeIntervalSince(requestedAt).rounded())
            recent.append("""
            the subscription was acknowledged \(late) s after the code was asked for, so it cannot have seen a \
            code sent before then: it was not prepared before the request (CodeSink.prepare), or it reconnected \
            since
            """)
        }
        return recent.isEmpty ? "no subscription or query events" : recent.joined(separator: "; ")
    }

    /// A query the API refused, by its error types and kinds only.
    struct QueryRefused: Error {
        let reason: String
        /// Untyped GraphQL errors only (`ListMfaInfoForms.isSchemaRefusal(_:)`): the API's schema has no such
        /// query or argument, or cannot answer it, and asking again cannot help.
        let byTheSchema: Bool
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
            throw QueryRefused(
                reason: "\(errors.count) errors \(errors.map(kind))",
                byTheSchema: ListMfaInfoForms.isSchemaRefusal(errors)
            )
        }
        guard status == 200, let json else {
            throw QueryRefused(reason: "HTTP \(status)", byTheSchema: false)
        }
        return ((json["data"] as? [String: Any])?["listMfaInfo"] as? [[String: Any]]) ?? []
    }

    /// A GraphQL error by its type, or by the kind its message names (AppSync's validation and type-mismatch
    /// errors carry no type), never by the message itself.
    private static func kind(_ error: [String: Any]) -> String {
        if let type = error["errorType"] as? String, !type.isEmpty {
            return type
        }
        let message = error["message"] as? String ?? ""
        if let range = message.range(of: #"Validation error of type [A-Za-z]+"#, options: .regularExpression) {
            return String(message[range].dropFirst("Validation error of type ".count))
        }
        if message.contains("type mismatch") {
            return "type mismatch"
        }
        return "untyped"
    }

    private static func parseTimestamp(_ text: String) -> Date? {
        let withFraction = ISO8601DateFormatter()
        withFraction.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return withFraction.date(from: text) ?? ISO8601DateFormatter().date(from: text)
    }
}

/// Which `listMfaInfo` forms to ask one API (`true`: the sandbox's `listMfaInfo(username:)`; `false`: the
/// plugin backends' argument-less one), from what it answered so far.
///
/// Both are asked, the sandbox's first, until one answers; from then on only that one, whatever fails
/// later: a backend's schema does not change during a run. Until then, a form refused by the schema
/// (`isSchemaRefusal(_:)`) is not asked again; any other failure leaves it to be asked on the next poll.
struct ListMfaInfoForms: Sendable, Equatable {
    /// The form that has answered, once one has.
    private(set) var answering: Bool?
    /// The forms the schema refused before any answered.
    private(set) var refusedBySchema: Set<Bool> = []

    /// The forms to ask now, in order.
    var toAsk: [Bool] {
        answering.map { [$0] } ?? [true, false].filter { !refusedBySchema.contains($0) }
    }

    /// `withUsername` answered. The first form to answer is kept.
    mutating func answered(_ withUsername: Bool) {
        if answering == nil {
            answering = withUsername
        }
    }

    /// `withUsername` failed. Recorded only when the schema refused it and no form has answered yet.
    mutating func refused(_ withUsername: Bool, byTheSchema: Bool) {
        guard byTheSchema, answering == nil else {
            return
        }
        refusedBySchema.insert(withUsername)
    }

    /// Whether GraphQL `errors` say the schema cannot answer the query: there are some, and none carries an
    /// `errorType`. AppSync's validation errors (no such field or argument) and type-mismatch errors (the
    /// plugin backends' argument-less `listMfaInfo`) are untyped; an authorization, resolver, throttling or
    /// internal error is typed, and transient.
    static func isSchemaRefusal(_ errors: [[String: Any]]) -> Bool {
        !errors.isEmpty && errors.allSatisfy { ($0["errorType"] as? String ?? "").isEmpty }
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
    /// When the current subscription was acknowledged.
    private(set) var connectedAt: Date?
    /// When the socket last received anything, keep-alives included.
    private var lastActivity = Date()
    /// How long AppSync may go without a keep-alive (`connection_ack`'s `connectionTimeoutMs`; 5 minutes
    /// unless it says otherwise). A socket quiet for longer is taken as dropped, and replaced.
    private var keepAliveTimeout: TimeInterval = 300

    init(api: CodeSinkAPI, receive: @escaping Receive, note: @escaping Note) {
        self.api = api
        self.receive = receive
        self.note = note
    }

    /// Returns once the subscription is acknowledged, or once connecting failed or took over 20 seconds. A
    /// connection that has heard nothing, not even a keep-alive, for longer than AppSync's keep-alive timeout
    /// is replaced first: a socket can go silent without its receive failing.
    func ensureConnected() async {
        if connected, let socket, Date().timeIntervalSince(lastActivity) > keepAliveTimeout {
            await note("subscription silent past its keep-alive timeout; reconnecting")
            disconnected(socket)
        }
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
            let ack = try await awaitMessage("connection_ack", on: socket)
            if let timeout = ((ack["payload"] as? [String: Any])?["connectionTimeoutMs"] as? NSNumber)?.doubleValue,
               timeout > 0 {
                keepAliveTimeout = timeout / 1_000
            }
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
        connectedAt = Date()
        lastActivity = Date()
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
                if socket === self.socket {
                    lastActivity = Date()
                }
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
    /// cancelled, which ends the pending receive with an error. Returns the message.
    @discardableResult
    private func awaitMessage(_ type: String, on socket: URLSessionWebSocketTask) async throws -> [String: Any] {
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
                return object
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
