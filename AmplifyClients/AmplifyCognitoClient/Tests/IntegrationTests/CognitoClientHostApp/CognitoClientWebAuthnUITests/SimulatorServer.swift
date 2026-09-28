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

    private static func post(_ path: String, _ device: String) async throws {
        var request = URLRequest(url: URL(string: endpoint + path)!)
        request.httpMethod = "POST"
        request.httpBody = try JSONEncoder().encode(["deviceId": device])
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        let response: URLResponse
        do {
            (_, response) = try await URLSession.shared.data(for: request)
        } catch {
            throw SimulatorServerError("""
            The simulator server is not running at \(endpoint) (\(error.localizedDescription)). Start it: \
            cd AmplifyPlugins/Auth/Tests/AuthWebAuthnApp/LocalServer && npm install && npm start
            """)
        }
        guard let status = (response as? HTTPURLResponse)?.statusCode, status < 300 else {
            throw SimulatorServerError("POST \(path) failed: \(response)")
        }
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
