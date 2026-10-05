//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import XCTest

/// The plugin's WebAuthn `LocalServer` (`AmplifyPlugins/Auth/Tests/AuthWebAuthnApp/LocalServer`), which
/// runs `xcrun simctl` on the host for the UI test: a UI test runs inside the simulator and cannot.
/// The client's harness reuses it unchanged; its `/uninstall` removes the plugin app's bundle
/// identifier, which is this app's too. Start it with `npm install && npm start` in that directory.
enum SimulatorServer {
    static let endpoint = "http://127.0.0.1:9294"

    /// Waits for the simulator to finish booting.
    static func boot(_ device: String) async throws {
        try await post("/boot", device)
    }

    /// Enrols Face ID on the simulator (Features > Face ID > Enrolled).
    static func enrollBiometrics(_ device: String) async throws {
        try await post("/enroll", device)
    }

    /// Presents a matching face (Features > Face ID > Matching Face).
    static func matchBiometrics(_ device: String) async throws {
        try await post("/match", device)
    }

    /// Uninstalls the app. Its passkeys stay in the simulator's Passwords store (they are kept per relying
    /// party, not in the app); their server-side credentials are deleted by the test or with the user.
    static func uninstallApp(_ device: String) async throws {
        try await post("/uninstall", device)
    }

    /// How long one request waits for the server's answer. The server answers once its job (its `simctl`
    /// commands) has ended, or after 15 s with HTTP 500 "Timed out …" while the job goes on; it also answers
    /// "Timed out …" for a job it stopped at its limit (45 s; 120 s for `/boot`). Either is retried like a
    /// time-out, and a retry while the job runs waits for that job instead of starting another.
    static let requestTimeout: TimeInterval = 20
    /// How many times a request is sent, 2 s apart, before it fails: the server can be briefly slow to
    /// answer (as the plugin's `AuthWebAuthnAppUITests.sendLocalServerRequest` retries a single `-1001`).
    static let attempts = 3

    /// Posts `path`, at most `attempts` times, each bounded by `requestTimeout`, so no call can hang a test or
    /// its teardown: without a bound, a teardown whose `/uninstall` never answered held the runner until
    /// XCTest's 10-minute allowance (WA-1, in a live run).
    private static func post(_ path: String, _ device: String) async throws {
        var request = URLRequest(url: URL(string: endpoint + path)!)
        request.httpMethod = "POST"
        request.httpBody = try JSONEncoder().encode(["deviceId": device])
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = requestTimeout
        var lastError: Error?
        var serverTimeout: String?
        for attempt in 1 ... attempts {
            do {
                let (data, response) = try await URLSession.shared.data(for: request)
                let status = (response as? HTTPURLResponse)?.statusCode ?? 0
                let body = String(bytes: data, encoding: .utf8) ?? ""
                if status == 500, body.hasPrefix("Timed out") {
                    // The server's job is still running, or hung and was stopped: as with a time-out, the next
                    // try can succeed.
                    serverTimeout = body
                    lastError = URLError(.timedOut)
                } else if status < 300 {
                    return
                } else {
                    // The server answered, and refused: its command failed, and sending it again will not help.
                    throw SimulatorServerError("POST \(path) failed: HTTP \(status)")
                }
            } catch let error as SimulatorServerError {
                throw error
            } catch {
                serverTimeout = nil
                lastError = error
            }
            if attempt < attempts {
                try await Task.sleep(nanoseconds: 2_000_000_000)
            }
        }
        if let serverTimeout {
            throw SimulatorServerError("""
            POST \(path): the simulator server's simctl command hung, \(attempts) times. Its last answer: \
            \(serverTimeout). Check the server's log.
            """, isTimeout: true)
        }
        let timedOut = (lastError as? URLError)?.code == .timedOut
        throw SimulatorServerError(timedOut ? """
        POST \(path) to the simulator server at \(endpoint) did not answer within \(Int(requestTimeout)) s, \
        \(attempts) times: its simctl command is stuck. Check the server's console.
        """ : """
        The simulator server is not running at \(endpoint) (\(lastError?.localizedDescription ?? "no answer")). \
        Start it: cd AmplifyPlugins/Auth/Tests/AuthWebAuthnApp/LocalServer && npm install && npm start
        """, isTimeout: timedOut)
    }

    /// The UDID of the simulator the test runs on, from the test bundle's path
    /// (`…/CoreSimulator/Devices/<UDID>/data/…`), as the plugin's UI test reads it.
    static var deviceIdentifier: String {
        get throws {
            let components = Bundle.main.bundleURL.pathComponents
            guard let index = components.firstIndex(of: "Devices"), components.indices.contains(index + 1) else {
                throw SimulatorServerError("Not running on a simulator: \(Bundle.main.bundleURL.path)")
            }
            return components[index + 1]
        }
    }
}

struct SimulatorServerError: Error, CustomStringConvertible {
    let description: String
    /// Whether every try timed out (the server's command hung, or it did not answer), rather than the server
    /// refusing the request or not running: sending the request again later can succeed.
    let isTimeout: Bool

    init(_ description: String, isTimeout: Bool = false) {
        self.description = description
        self.isTimeout = isTimeout
    }
}
