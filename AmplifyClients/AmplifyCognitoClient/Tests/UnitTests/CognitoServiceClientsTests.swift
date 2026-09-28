//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AmplifyFoundation
import AWSCognitoIdentity
import AWSCognitoIdentityProvider
import SmithyHTTPAPI
import SmithyIdentity
import XCTest
@_spi(AmplifyExperimental) @testable import AmplifyCognitoClient

/// SDK client construction at parity with the plugin: the user agent, the signing
/// region, the credential identity resolver, and the escape hatch's place in the order.
final class CognitoServiceClientsTests: XCTestCase {

    private static let userPoolRegion = "eu-west-1"
    private static let identityPoolRegion = "us-east-2"

    private func configuration() throws -> AuthClientConfiguration {
        try AuthClientConfiguration(
            userPool: .init(poolId: "eu-west-1_AbCdEf123", appClientId: "app-client-1", region: Self.userPoolRegion),
            identityPool: .init(
                poolId: "us-east-2:0e3c1a52-7f0b-4a55-9d7a-2b6f3c1d9e88",
                region: Self.identityPoolRegion
            )
        )
    }

    // MARK: User agent

    /// The escape hatch's own HTTP engine still gets the Amplify user agent.
    ///
    /// - Given: an escape-hatch closure that installs a recording HTTP engine on the user pool client
    /// - When:
    ///    - the user pool client sends `InitiateAuth`
    /// - Then:
    ///    - the request reaches the recording engine, so the unsigned operation never asked the resolver
    ///    - its `User-Agent` ends with the plugin's `lib/` token and `md/amplify-cognito`, each exactly once
    ///
    func testUserPoolRequestsCarryTheAmplifyUserAgent() async throws {
        let recorder = RecordingEngine()
        let clients = try CognitoServiceClients(configuration: configuration(), configureUserPoolClient: { config in
            config.httpClientEngine = recorder
        })

        await XCTAssertThrowsStop {
            _ = try await XCTUnwrap(clients.userPool).initiateAuth(input: .init(
                authFlow: .userSrpAuth,
                authParameters: ["USERNAME": "alice", "SRP_A": "abc"],
                clientId: "app-client-1"
            ))
        }

        try Self.assertAmplifyUserAgent(recorder)
    }

    /// The identity client, which has no escape hatch, gets the Amplify user agent too.
    ///
    /// - Given: clients built over a recording base HTTP engine
    /// - When:
    ///    - the identity client sends `GetId`
    /// - Then:
    ///    - the request reaches the recording engine
    ///    - its `User-Agent` ends with the plugin's `lib/` token and `md/amplify-cognito`, each exactly once
    ///
    func testIdentityRequestsCarryTheAmplifyUserAgent() async throws {
        let recorder = RecordingEngine()
        let clients = try CognitoServiceClients(
            configuration: configuration(),
            configureUserPoolClient: nil,
            baseHTTPClientEngine: recorder
        )

        await XCTAssertThrowsStop {
            _ = try await XCTUnwrap(clients.identity).getId(input: .init(
                identityPoolId: "us-east-2:0e3c1a52-7f0b-4a55-9d7a-2b6f3c1d9e88"
            ))
        }

        try Self.assertAmplifyUserAgent(recorder)
    }

    // MARK: Credential identity resolver

    /// The resolver itself never produces credentials, and its advice fits the client it is on.
    ///
    /// - Given: `CognitoUnsignedOperationResolver` for the user pool client and for the identity client
    /// - When:
    ///    - each is asked for an identity
    /// - Then:
    ///    - each throws `AuthClientError.configuration`
    ///    - the user pool advice points at `configureUserPoolClient`; the identity advice, since that
    ///      client has no escape hatch, says to build a separate `CognitoIdentityClient`
    ///
    func testResolverAlwaysThrows() async {
        for client in [CognitoUnsignedOperationResolver.Client.userPool, .identity] {
            do {
                _ = try await CognitoUnsignedOperationResolver(for: client).getIdentity(identityProperties: nil)
                XCTFail("expected the resolver to throw")
            } catch {
                Self.assertConfigurationError(error, for: client)
            }
        }
    }

    /// Both SDK clients use the throwing resolver, never the SDK's default chain.
    ///
    /// - Given: clients built with no escape hatch
    /// - When:
    ///    - each client's configured resolver is read
    /// - Then:
    ///    - both are `CognitoUnsignedOperationResolver`, each for its own client
    ///
    func testBothClientsUseTheThrowingResolver() throws {
        let clients = try CognitoServiceClients(configuration: configuration(), configureUserPoolClient: nil)
        let userPool = try XCTUnwrap(clients.userPool).config.awsCredentialIdentityResolver
        let identity = try XCTUnwrap(clients.identity).config.awsCredentialIdentityResolver

        XCTAssertEqual((userPool as? CognitoUnsignedOperationResolver)?.client, .userPool)
        XCTAssertEqual((identity as? CognitoUnsignedOperationResolver)?.client, .identity)
    }

    /// A signed call fails loudly, before anything is sent.
    ///
    /// - Given: clients built over a recording base HTTP engine
    /// - When:
    ///    - the user pool client calls `AdminGetUser` and the identity client calls `DescribeIdentityPool`,
    ///      two operations that need AWS credentials
    /// - Then:
    ///    - each throws `AuthClientError.configuration`, with its own client's advice
    ///    - no request reaches the HTTP engine
    ///
    func testSignedOperationsFailInTheResolver() async throws {
        let recorder = RecordingEngine()
        let clients = try CognitoServiceClients(
            configuration: configuration(),
            configureUserPoolClient: nil,
            baseHTTPClientEngine: recorder
        )

        do {
            _ = try await XCTUnwrap(clients.userPool).adminGetUser(input: .init(
                userPoolId: "eu-west-1_AbCdEf123",
                username: "alice"
            ))
            XCTFail("expected AdminGetUser to fail in the resolver")
        } catch {
            Self.assertConfigurationError(error, for: .userPool)
        }
        do {
            _ = try await XCTUnwrap(clients.identity).describeIdentityPool(input: .init(
                identityPoolId: "us-east-2:0e3c1a52-7f0b-4a55-9d7a-2b6f3c1d9e88"
            ))
            XCTFail("expected DescribeIdentityPool to fail in the resolver")
        } catch {
            Self.assertConfigurationError(error, for: .identity)
        }

        XCTAssertEqual(recorder.userAgents, [])
    }

    // MARK: Signing region and the escape hatch's place in the order

    /// Each client signs for its own pool's region, as the plugin's do. The SDK's `Config(region:)` already
    /// did this; the explicit value states the intent, and this test keeps it from regressing.
    ///
    /// - Given: a user pool and an identity pool in different regions
    /// - When:
    ///    - the clients are built with no escape hatch
    /// - Then:
    ///    - each client's `region` and `signingRegion` are its own pool's region
    ///
    func testSigningRegionIsEachPoolsRegion() throws {
        let clients = try CognitoServiceClients(configuration: configuration(), configureUserPoolClient: nil)
        let userPool = try XCTUnwrap(clients.userPool).config
        let identity = try XCTUnwrap(clients.identity).config

        XCTAssertEqual(userPool.region, Self.userPoolRegion)
        XCTAssertEqual(userPool.signingRegion, Self.userPoolRegion)
        XCTAssertEqual(identity.region, Self.identityPoolRegion)
        XCTAssertEqual(identity.signingRegion, Self.identityPoolRegion)
    }

    /// The escape hatch runs after the parity settings, so it sees them and its changes win.
    ///
    /// - Given: an escape-hatch closure that records what it sees, then replaces the signing region and
    ///   the resolver
    /// - When:
    ///    - the clients are built
    /// - Then:
    ///    - the closure saw the pool's signing region and the throwing resolver already set
    ///    - the built user pool client keeps the closure's signing region and resolver
    ///    - the identity client, which the closure does not touch, keeps the parity settings
    ///
    func testEscapeHatchRunsAfterTheParitySettings() throws {
        let seen = SeenSettings()
        let custom = StaticAWSCredentialIdentityResolver(AWSCredentialIdentity(accessKey: "AKID", secret: "secret"))

        let clients = try CognitoServiceClients(configuration: configuration(), configureUserPoolClient: { config in
            seen.record(
                signingRegion: config.signingRegion,
                resolverIsThrowing: config.awsCredentialIdentityResolver is CognitoUnsignedOperationResolver
            )
            config.signingRegion = "ap-south-1"
            config.awsCredentialIdentityResolver = custom
        })
        let userPool = try XCTUnwrap(clients.userPool).config
        let identity = try XCTUnwrap(clients.identity).config

        XCTAssertEqual(seen.signingRegion, Self.userPoolRegion)
        XCTAssertEqual(seen.resolverIsThrowing, true)
        XCTAssertEqual(userPool.signingRegion, "ap-south-1")
        XCTAssertTrue(userPool.awsCredentialIdentityResolver is StaticAWSCredentialIdentityResolver)
        XCTAssertEqual(identity.signingRegion, Self.identityPoolRegion)
        XCTAssertTrue(identity.awsCredentialIdentityResolver is CognitoUnsignedOperationResolver)
    }

    // MARK: Helpers

    private static func assertAmplifyUserAgent(
        _ recorder: RecordingEngine,
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws {
        let userAgents = recorder.userAgents
        XCTAssertFalse(userAgents.isEmpty, "no request reached the HTTP engine", file: file, line: line)
        let lib = "lib/\(AmplifyMetadata.platformName)#\(AmplifyMetadata.version)"
        let metadata = "md/amplify-cognito#\(AmplifyMetadata.version)"
        for userAgent in userAgents {
            let tokens = try XCTUnwrap(userAgent, "a request had no User-Agent", file: file, line: line)
                .split(separator: " ").map(String.init)
            XCTAssertEqual(Array(tokens.suffix(2)), [lib, metadata], file: file, line: line)
            XCTAssertEqual(tokens.count(where: { $0 == lib }), 1, "the lib token is added once", file: file, line: line)
            XCTAssertEqual(tokens.count(where: { $0 == metadata }), 1, file: file, line: line)
        }
    }

    private static func assertConfigurationError(
        _ error: Error,
        for client: CognitoUnsignedOperationResolver.Client,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        guard case .configuration(_, let suggestion, _) = error as? AuthClientError else {
            XCTFail("expected AuthClientError.configuration, got \(error)", file: file, line: line)
            return
        }
        switch client {
        case .userPool:
            XCTAssertTrue(suggestion.contains("Options.configureUserPoolClient"), suggestion, file: file, line: line)
        case .identity:
            XCTAssertTrue(suggestion.contains("build your own CognitoIdentityClient"), suggestion, file: file, line: line)
            XCTAssertFalse(suggestion.contains("configureUserPoolClient"), suggestion, file: file, line: line)
        }
    }

    private func XCTAssertThrowsStop(
        _ body: () async throws -> Void,
        file: StaticString = #filePath,
        line: UInt = #line
    ) async {
        do {
            try await body()
            XCTFail("expected the recording engine to stop the request", file: file, line: line)
        } catch is RecordingEngine.Stop {
            // Expected: the recording engine short-circuits every request.
        } catch {
            XCTFail("expected RecordingEngine.Stop, got \(error)", file: file, line: line)
        }
    }
}

/// Records each request's `User-Agent`, then stops the request, so nothing reaches the network.
///
/// - Note: `@unchecked Sendable`: the recorded list is only touched while holding `lock`.
private final class RecordingEngine: HTTPClient, @unchecked Sendable {
    struct Stop: Error {}

    private let lock = NSLock()
    private var recorded: [String?] = []

    var userAgents: [String?] {
        lock.lock()
        defer { lock.unlock() }
        return recorded
    }

    func send(request: SmithyHTTPAPI.HTTPRequest) async throws -> SmithyHTTPAPI.HTTPResponse {
        record(request.headers.value(for: "User-Agent"))
        throw Stop()
    }

    private func record(_ userAgent: String?) {
        lock.lock()
        recorded.append(userAgent)
        lock.unlock()
    }
}

/// What the escape-hatch closure saw.
///
/// - Note: `@unchecked Sendable`: the closure runs synchronously, inside the initializer, before any
///   read; the lock makes that ordering explicit.
private final class SeenSettings: @unchecked Sendable {
    private let lock = NSLock()
    private var values: (signingRegion: String?, resolverIsThrowing: Bool)?

    var signingRegion: String? {
        lock.lock()
        defer { lock.unlock() }
        return values?.signingRegion
    }

    var resolverIsThrowing: Bool? {
        lock.lock()
        defer { lock.unlock() }
        return values?.resolverIsThrowing
    }

    func record(signingRegion: String?, resolverIsThrowing: Bool) {
        lock.lock()
        values = (signingRegion, resolverIsThrowing)
        lock.unlock()
    }
}
