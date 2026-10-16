//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AmplifyFoundation
import AmplifyFoundationBridge
@_spi(PluginHTTPClientEngine)
import InternalAmplifyCredentials
import SmithyHTTPAPI
import XCTest

/// The plugins and the standalone clients each carry their own copy of the library version and platform
/// name: `AmplifyAWSServiceConfiguration` (plugins) and `AmplifyMetadata` (clients). Both go into the
/// `lib/` token of the `User-Agent`, which is what attribution keys on, so they must never split. The
/// release workflow bumps both; these tests fail if it, or a hand edit, bumps only one.
final class AmplifyVersionParityTests: XCTestCase {

    /// Pins the two copies of the version constants to each other.
    ///
    /// - Given: the plugins' `AmplifyAWSServiceConfiguration` and the clients' `AmplifyMetadata`
    /// - When:
    ///    - their version and platform name are read
    /// - Then:
    ///    - they are equal, so the plugins and the clients report the same library version
    ///
    func testVersionConstantsMatch() {
        XCTAssertEqual(AmplifyMetadata.version, AmplifyAWSServiceConfiguration.amplifyVersion)
        XCTAssertEqual(AmplifyMetadata.platformName, AmplifyAWSServiceConfiguration.platformName)
    }

    /// Pins the `lib/` token each family's user-agent engine actually sends.
    ///
    /// - Given: the plugins' `UserAgentSettingClientEngine` and the clients' `UserAgentClientEngine`, each
    ///   wrapping a recording engine
    /// - When:
    ///    - each sends a request that has no `User-Agent`
    /// - Then:
    ///    - the plugins' engine sends exactly `AmplifyAWSServiceConfiguration.userAgentLib`
    ///    - the clients' engine sends that same token first, before its own `md/` metadata
    ///
    func testUserAgentLibTokensMatch() async throws {
        let pluginTarget = RecordingEngine()
        _ = try await UserAgentSettingClientEngine(target: pluginTarget).send(request: Self.request())
        let pluginUserAgent = try XCTUnwrap(pluginTarget.userAgent).trimmingCharacters(in: .whitespaces)

        let clientTarget = RecordingEngine()
        _ = try await UserAgentClientEngine(target: clientTarget, additionalMetadata: ["md/amplify-cognito"])
            .send(request: Self.request())
        let clientTokens = try XCTUnwrap(clientTarget.userAgent).split(separator: " ").map(String.init)

        XCTAssertEqual(pluginUserAgent, AmplifyAWSServiceConfiguration.userAgentLib)
        XCTAssertEqual(clientTokens, [pluginUserAgent, "md/amplify-cognito#\(AmplifyMetadata.version)"])
    }

    private static func request() -> SmithyHTTPAPI.HTTPRequest {
        HTTPRequest(method: .get, endpoint: .init(host: "amplify"))
    }
}

// `@unchecked Sendable`: `HTTPClient` is `Sendable`; each test sends one request through it, and reads
// the header only after the send returns.
private final class RecordingEngine: HTTPClient, @unchecked Sendable {
    var userAgent: String?

    func send(request: SmithyHTTPAPI.HTTPRequest) async throws -> SmithyHTTPAPI.HTTPResponse {
        userAgent = request.headers.value(for: "User-Agent")
        return HTTPResponse(body: .empty, statusCode: .accepted)
    }
}
