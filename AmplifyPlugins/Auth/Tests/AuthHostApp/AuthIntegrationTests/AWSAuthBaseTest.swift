//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AWSCognitoAuthPlugin
import XCTest
@testable import Amplify

private let internalTestDomain = "@amplify-swift-gamma.awsapps.com"

// `@unchecked Sendable`: `XCTestCase` is not `Sendable`, but the test body is captured by the
// `@Sendable` closures the API now takes. XCTest runs one test at a time.
class AWSAuthBaseTest: XCTestCase, @unchecked Sendable {

    let networkTimeout = TimeInterval(5)

    var defaultTestEmail = "test-\(UUID().uuidString)\(internalTestDomain)"
    var defaultTestPassword = UUID().uuidString

    var randomEmail: String {
        "test-\(UUID().uuidString)\(internalTestDomain)"
    }

    var randomPhoneNumber: String {
        "+1" + (1 ... 10)
            .map { _ in String(Int.random(in: 0 ... 9)) }
            .joined()
    }

    var amplifyConfigurationFile = "testconfiguration/AWSCognitoAuthPluginIntegrationTests-amplifyconfiguration"
    var amplifyOutputsFile =
        "testconfiguration/AWSCognitoAuthPluginIntegrationTests-amplify_outputs"
    let credentialsFile = "testconfiguration/AWSCognitoAuthPluginIntegrationTests-credentials"
    let keychainAccessGroup = "94KV3E626L.com.aws.amplify.auth.AuthHostAppShared"
    let keychainAccessGroup2 = "94KV3E626L.com.aws.amplify.auth.AuthHostAppShared2"
    let keychainAccessGroupWatch = "W3DRXD72QU.com.amazon.aws.amplify.swift.AuthWatchAppShared"
    let keychainAccessGroupWatch2 = "W3DRXD72QU.com.amazon.aws.amplify.swift.AuthWatchAppShared2"

    var amplifyConfiguration: AmplifyConfiguration!
    var amplifyOutputs: AmplifyOutputsData!

    var onlyUseGen2Configuration = false

    /// The custom-auth challenge answer of a backend whose triggers use a fixed one (the sandbox's
    /// `custom_challenge_answer`), or nil: `AuthCustomSignInTests` skip without it.
    var customChallengeAnswer: String?
    /// Users in FORCE_CHANGE_PASSWORD, each usable once, and their temporary password
    /// (`new_password_required_usernames`, comma-separated, and `new_password_required_temporary_password`):
    /// `AuthSRPSignInTests.testNewPasswordRequired` skips without them.
    var newPasswordRequiredUsernames: [String] = []
    var newPasswordRequiredTemporaryPassword: String?

    var useGen2Configuration: Bool {
        ProcessInfo.processInfo.arguments.contains("GEN2") || onlyUseGen2Configuration
    }

    override func setUp() async throws {
        try await super.setUp()
        initializeAmplify()
        _ = await Amplify.Auth.signOut()
    }

    override func tearDown() async throws {
        try await super.tearDown()
        subscription?.cancel()
        otpCodes.reset()
        await Amplify.reset()
    }

    func initializeAmplify() {
        do {
            let credentialsConfiguration = (try? TestConfigHelper.retrieveCredentials(forResource: credentialsFile)) ?? [:]
            defaultTestEmail = credentialsConfiguration["test_email_1"] ?? defaultTestEmail
            defaultTestPassword = credentialsConfiguration["password"] ?? defaultTestPassword
            customChallengeAnswer = credentialsConfiguration["custom_challenge_answer"]
            newPasswordRequiredUsernames = (credentialsConfiguration["new_password_required_usernames"] ?? "")
                .split(separator: ",").map(String.init)
            newPasswordRequiredTemporaryPassword = credentialsConfiguration["new_password_required_temporary_password"]
            let authPlugin = AWSCognitoAuthPlugin()
            try Amplify.add(plugin: authPlugin)

            if useGen2Configuration {
                let data = try TestConfigHelper.retrieve(forResource: amplifyOutputsFile)
                try Amplify.configure(with: .data(data))
            } else {
                let configuration = try TestConfigHelper.retrieveAmplifyConfiguration(
                    forResource: amplifyConfigurationFile)
                amplifyConfiguration = configuration
                try Amplify.configure(amplifyConfiguration)
            }
            Amplify.Logging.logLevel = .verbose
            print("Amplify configured with auth plugin")
        } catch {
            print(error)
            initializeWithLocalResources()
        }
    }

    /// Expires the signed-in session in the keychain: the tokens' expiry goes into the past and the
    /// refresh token becomes one Cognito rejects, so the next refresh fails. Works for both Gen1 and Gen2
    /// configurations.
    func invalidateStoredSession() throws {
        if useGen2Configuration {
            try AuthSessionHelper.invalidateSession(withOutputs: TestConfigHelper.retrieve(forResource: amplifyOutputsFile))
        } else {
            AuthSessionHelper.invalidateSession(with: amplifyConfiguration)
        }
    }

    /// Resets Amplify and configures it again, so the plugin loads its session from the keychain rather
    /// than keeping the one it holds in memory. Hub listeners are removed by the reset.
    func reconfigureFromKeychain() async {
        await Amplify.reset()
        initializeAmplify()
    }

    func initializeWithLocalResources() {
        let region = JSONValue(stringLiteral: "xx")
        let userPoolID = JSONValue(stringLiteral: "xx")
        let userPooldAppClientID = JSONValue(stringLiteral: "xx")

        let identityPoolID = JSONValue(stringLiteral: "xx")
        do {
            let authConfiguration = AuthCategoryConfiguration(plugins: [
                "awsCognitoAuthPlugin": [
                    "UserAgent": "aws-amplify/cli",
                    "Version": "0.1.0",
                    "IdentityManager": [
                        "Default": []
                    ],
                    "CredentialsProvider": [
                        "CognitoIdentity": [
                            "Default": [
                                "PoolId": identityPoolID,
                                "Region": region
                            ]
                        ]
                    ],
                    "CognitoUserPool": [
                        "Default": [
                            "PoolId": userPoolID,
                            "AppClientId": userPooldAppClientID,
                            "Region": region
                        ]
                    ]
                ]
            ]
            )
            let configuration = AmplifyConfiguration(auth: authConfiguration)
            let authPlugin = AWSCognitoAuthPlugin()
            try Amplify.add(plugin: authPlugin)
            try Amplify.configure(configuration)
        } catch {
            print(error)
            XCTFail("Amplify configuration failed")
        }
    }

    /// OTP codes by lower-cased username. Written from the subscription's task and read by `otp(for:)`,
    /// so every access goes through the lock.
    let otpCodes = OTPCodeStore()
    var subscription: AmplifyAsyncThrowingSequence<GraphQLSubscriptionEvent<[String: JSONValue]>>?

    let document: String = """
    subscription OnCreateMfaInfo {
        onCreateMfaInfo {
          username
          code
          expirationTime
        }
    }
    """

    /// What happened to the subscription and to the last `otp(for:)` wait, for failure messages.
    var otpDiagnostics: String {
        otpCodes.diagnostics
    }

    /// Function to create a subscription and store OTP codes in a dictionary
    func subscribeToOTPCreation() async {
        subscription = Amplify.API.subscribe(request: .init(document: document, responseType: [String: JSONValue].self))

        func waitForSubscriptionConnection(
            subscription: AmplifyAsyncThrowingSequence<GraphQLSubscriptionEvent<[String: JSONValue]>>
        ) async throws {
            for try await subscriptionEvent in subscription {
                if case .connection(let subscriptionConnectionState) = subscriptionEvent {
                    print("Subscription connect state is \(subscriptionConnectionState)")
                    otpCodes.note("connection \(subscriptionConnectionState) (before listening)")
                    if subscriptionConnectionState == .connected {
                        return
                    }
                }
            }
        }

        guard let subscription else { return }

        // The helper silently continues on timeout, so allow 30 seconds for the OTP subscription to
        // connect before sign-up (otherwise the one-shot `onCreateMfaInfo` event is missed).
        await wait(name: "Subscription Connection Waiter", timeout: 30.0) {
            try await waitForSubscriptionConnection(subscription: subscription)
        }

        // Create the subscription and listen for OTP code events
        let codeStore = otpCodes
        Task {
            do {
                for try await subscriptionEvent in subscription {
                    switch subscriptionEvent {
                    case .connection(let subscriptionConnectionState):
                        print("Subscription connect state is \(subscriptionConnectionState)")
                        // A change after connecting (a drop, a reconnect) is where codes can go missing.
                        codeStore.note("connection \(subscriptionConnectionState) (while listening)")
                    case .data(let result):
                        switch result {
                        case .success(let otpResult):
                            print("Successfully got OTP code from subscription: \(otpResult)")
                            if let eventUsername = otpResult["onCreateMfaInfo"]?.asObject?["username"]?.stringValue,
                               let code = otpResult["onCreateMfaInfo"]?.asObject?["code"]?.stringValue {
                                // Store the code in the dictionary for the given username
                                codeStore.store(code, for: eventUsername)
                            }
                        case .failure(let error):
                            print("Got failed result with \(error.errorDescription)")
                            codeStore.note("data error: \(error.errorDescription)")
                        }
                    }
                }
                codeStore.note("subscription finished")
            } catch {
                print("Subscription terminated with error: \(error)")
                codeStore.note("subscription terminated: \(error)")
            }
        }

        // `.connected` (start_ack) can precede AppSync being ready to fan `onCreateMfaInfo` events
        // out to this subscription. The OTP event is one-shot — if the caller signs up in that
        // window it is missed and `otp(for:)` polls in vain, surfacing as "Failed to retrieve the
        // OTP code". Give the server a brief moment to finish registering before returning to the
        // caller (which signs up immediately). The data listener above is already running.
        try? await Task.sleep(nanoseconds: 2_000_000_000)
    }

    /// Waits up to 60 s (OTP delivery, email or SMS to Lambda to AppSync, can take longer than 30 s) for
    /// `username`'s next code. The subscription delivers it; from the fifth second
    /// on, every third second, the code sink is also queried directly, in case the subscription missed
    /// the event. A code already returned is never returned again.
    func otp(for username: String) async throws -> String? {
        let lowerCasedUsername = username.lowercased()
        otpCodes.beginWait(for: lowerCasedUsername)
        for second in 0 ..< 60 {
            if let code = otpCodes.take(for: lowerCasedUsername) {
                return code
            }
            if second >= 5, second % 3 == 2, let code = await queriedOTP(for: lowerCasedUsername) {
                otpCodes.note("code found by query, not by the subscription, after \(second) s")
                return code
            }
            try await Task.sleep(nanoseconds: 1_000_000_000)
        }
        otpCodes.note("no code for the user after 60 s")
        return nil
    }

    /// The newest code for `username` in the code sink that has not been returned yet. The sandbox's sink
    /// takes `listMfaInfo(username:)`; the plugin's own backend (EmailMFATests/README.md) has an
    /// argument-less `listMfaInfo`, which is tried when the first form is rejected.
    private func queriedOTP(for username: String) async -> String? {
        let fields = "username code expirationTime"
        let requests: [GraphQLRequest<JSONValue>] = [
            // The sandbox's items also carry a server-set createdAt, the reliable order when two codes
            // share an expiration second.
            .init(
                document: "query ListMfaInfo($username: String!) { listMfaInfo(username: $username) { \(fields) createdAt } }",
                variables: ["username": username],
                responseType: JSONValue.self
            ),
            .init(document: "query ListMfaInfo { listMfaInfo { \(fields) } }", responseType: JSONValue.self)
        ]
        for request in requests {
            guard let response = try? await Amplify.API.query(request: request),
                  case .success(let data) = response,
                  case .array(let items) = data["listMfaInfo"] ?? .null
            else {
                continue
            }
            let candidates = items.compactMap { item -> (code: String, createdAt: String, expiration: Double)? in
                guard item["username"]?.stringValue?.lowercased() == username,
                      let code = item["code"]?.stringValue else {
                    return nil
                }
                return (code, item["createdAt"]?.stringValue ?? "", item["expirationTime"]?.doubleValue ?? 0)
            }
            // Newest first: by createdAt (ISO 8601, so it sorts as text) where present, else by expiry.
            let newestFirst = candidates.sorted { ($0.createdAt, $0.expiration) > ($1.createdAt, $1.expiration) }
            return otpCodes.newestUnused(newestFirst.map(\.code), for: username)
        }
        return nil
    }
}

/// The OTP codes the subscription delivers, and what happened while waiting for them, behind a lock:
/// the subscription's task writes while `otp(for:)` reads.
final class OTPCodeStore: @unchecked Sendable {
    private let lock = NSLock()
    private var codes: [String: String] = [:]
    private var used: [String: Set<String>] = [:]
    private var events: [String] = []

    func store(_ code: String, for username: String) {
        lock.withLock { codes[username.lowercased()] = code }
    }

    /// The delivered code for `username`, once: it is marked used.
    func take(for username: String) -> String? {
        lock.withLock {
            guard let code = codes.removeValue(forKey: username), !(used[username]?.contains(code) ?? false) else {
                return nil
            }
            used[username, default: []].insert(code)
            return code
        }
    }

    /// The first of `candidates` (newest first) not returned yet, marked used.
    func newestUnused(_ candidates: [String], for username: String) -> String? {
        lock.withLock {
            guard let code = candidates.first(where: { !(used[username]?.contains($0) ?? false) }) else {
                return nil
            }
            used[username, default: []].insert(code)
            if codes[username] == code {
                codes.removeValue(forKey: username)
            }
            return code
        }
    }

    func beginWait(for username: String) {
        note("waiting for a code for \(username)")
    }

    func note(_ event: String) {
        lock.withLock { events.append(event) }
    }

    var diagnostics: String {
        lock.withLock { events.isEmpty ? "(no subscription events)" : events.joined(separator: "; ") }
    }

    func reset() {
        lock.withLock {
            codes = [:]
            used = [:]
            events = []
        }
    }
}

class TestConfigHelper {

    static func retrieveAmplifyConfiguration(forResource: String) throws -> AmplifyConfiguration {
        let data = try retrieve(forResource: forResource)
        return try AmplifyConfiguration.decodeAmplifyConfiguration(from: data)
    }

    static func retrieveCredentials(forResource: String) throws -> [String: String] {
        let data = try retrieve(forResource: forResource)

        let jsonOptional = try JSONSerialization.jsonObject(with: data, options: []) as? [String: String]
        guard let json = jsonOptional else {
            throw TestConfigError.jsonError("Could not deserialize `\(forResource)` into JSON object")
        }

        return json
    }

    static func retrieve(forResource: String) throws -> Data {
        guard let path = Bundle(for: self).path(forResource: forResource, ofType: "json") else {
            throw TestConfigError.bundlePathError("Could not retrieve configuration file: \(forResource)")
        }

        let url = URL(fileURLWithPath: path)
        return try Data(contentsOf: url)
    }
}

enum TestConfigError: Error {

    case jsonError(String)

    case bundlePathError(String)
}
