//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

@_spi(AmplifyExperimental) @testable import AmplifyCognitoClient
import AmplifyFoundation
import XCTest

/// How the client builds its SDK clients, seen on the wire.
final class UserAgentTests: ClientIntegrationTestCase {

    /// Every user pool request the client sends carries the Amplify user agent, once (UA-1).
    ///
    /// The client's credential resolver for the user pool client always throws, so this run (and every
    /// other suite's) would already fail on any operation that got signed by accident.
    ///
    /// - Given: a client with the recorder installed
    /// - When:
    ///    - alice signs in, the session is force-refreshed, and alice signs out
    /// - Then:
    ///    - the recorder saw `InitiateAuth`, `RespondToAuthChallenge`, `GetTokensFromRefreshToken` and
    ///      `RevokeToken`
    ///    - every recorded request's `User-Agent` contains `lib/amplify-swift#<version>` exactly once and
    ///      `md/amplify-cognito#<version>` exactly once, `<version>` being `AmplifyMetadata.version`
    ///
    func testEveryCognitoRequestCarriesTheAmplifyUserAgent() async throws {
        let configuration = try IntegrationTestEnvironment.configuration()
        let alice = try IntegrationTestEnvironment.users().alice
        let sessionId = try makeSessionID("alice")
        let recorder = RecordingHTTPClient()
        let client = try AmplifyCognitoClient(
            configuration: configuration,
            options: .init(sessionId: sessionId, configureUserPoolClient: recorder.configureUserPoolClient)
        )

        _ = try await client.signIn(username: alice.username, password: alice.password)
        _ = try await client.fetchAuthSession(options: .init(forceRefresh: true)).userPoolTokensResult.get()
        let signOut = try await client.signOut()

        XCTAssertEqual(signOut, .complete)
        let operations = Set(recorder.operations)
        for expected in ["InitiateAuth", "RespondToAuthChallenge", "GetTokensFromRefreshToken", "RevokeToken"] {
            XCTAssertTrue(operations.contains(expected), "no \(expected) in \(recorder.operations)")
        }
        let library = "lib/amplify-swift#\(AmplifyMetadata.version)"
        let metadata = "md/amplify-cognito#\(AmplifyMetadata.version)"
        for request in recorder.requests {
            let operation = request.operation ?? "?"
            let userAgent = try XCTUnwrap(request.userAgent, "\(operation) has no User-Agent")
            XCTAssertEqual(occurrences(of: library, in: userAgent), 1, "\(operation): \(userAgent)")
            XCTAssertEqual(occurrences(of: metadata, in: userAgent), 1, "\(operation): \(userAgent)")
        }
    }

    private func occurrences(of token: String, in string: String) -> Int {
        string.components(separatedBy: token).count - 1
    }
}
