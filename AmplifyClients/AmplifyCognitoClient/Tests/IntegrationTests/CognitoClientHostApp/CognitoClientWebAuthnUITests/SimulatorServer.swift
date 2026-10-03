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

    /// How long one request waits for the server's answer. The server answers once its `simctl` command
    /// returns, and sends nothing before, so this bounds the whole request.
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
        for attempt in 1 ... attempts {
            do {
                let (_, response) = try await URLSession.shared.data(for: request)
                guard let status = (response as? HTTPURLResponse)?.statusCode, status < 300 else {
                    let status = (response as? HTTPURLResponse)?.statusCode ?? 0
                    throw SimulatorServerError("POST \(path) failed: HTTP \(status)")
                }
                return
            } catch let error as SimulatorServerError {
                // The server answered, and refused: its command failed, and sending it again will not help.
                throw error
            } catch {
                lastError = error
                if attempt < attempts {
                    try await Task.sleep(nanoseconds: 2_000_000_000)
                }
            }
        }
        let timedOut = (lastError as? URLError)?.code == .timedOut
        throw SimulatorServerError(timedOut ? """
        POST \(path) to the simulator server at \(endpoint) did not answer within \(Int(requestTimeout)) s, \
        \(attempts) times: its simctl command is stuck. Check the server's console.
        """ : """
        The simulator server is not running at \(endpoint) (\(lastError?.localizedDescription ?? "no answer")). \
        Start it: cd AmplifyPlugins/Auth/Tests/AuthWebAuthnApp/LocalServer && npm install && npm start
        """)
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

    init(_ description: String) {
        self.description = description
    }
}
