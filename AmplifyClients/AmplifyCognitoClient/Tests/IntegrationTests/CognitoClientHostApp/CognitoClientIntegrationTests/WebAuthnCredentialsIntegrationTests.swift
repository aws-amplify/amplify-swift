//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

@_spi(AmplifyExperimental) import AmplifyCognitoClient
import Foundation
import XCTest

/// WebAuthn credential management, headless: `listWebAuthnCredentials(options:)` and
/// `deleteWebAuthnCredential(credentialId:)` through the client against the WebAuthn pool (U-WA, P-10).
///
/// No passkey is registered here, so nothing needs the simulator's passkey sheet or Face ID: a fresh user has
/// no credentials, and the one to delete does not exist. Associate, and a list holding one passkey, are the
/// UI rows (WA-1). Each user is a fresh `ccit-` user on the WebAuthn pool, deleted at teardown after its
/// session is signed out. No assertion prints an identifier or a secret.
final class WebAuthnCredentialsIntegrationTests: ClientIntegrationTestCase {

    /// - Given: a fresh user on the WebAuthn pool, signed in through the client, who has registered no
    ///   passkey
    /// - When:
    ///    - the user lists its credentials with the default options, and with a page size of 1
    /// - Then:
    ///    - both pages are empty with no next token, and each was one `ListWebAuthnCredentials` request
    func testListOnAUserWithNoPasskeysIsEmpty() async throws {
        let recorder = RecordingHTTPClient()
        let client = try await signedInClient("wa-list", recorder: recorder)

        let defaultPage = try await client.listWebAuthnCredentials()
        let smallPage = try await client.listWebAuthnCredentials(options: .init(pageSize: 1))

        // Booleans, not XCTAssertEqual on the pages: a failure must not print a credential's identifiers.
        XCTAssertTrue(defaultPage.credentials.isEmpty, "The default page is not empty")
        XCTAssertTrue(defaultPage.nextToken == nil, "The default page has a next token")
        XCTAssertTrue(smallPage.credentials.isEmpty, "The page of 1 is not empty")
        XCTAssertTrue(smallPage.nextToken == nil, "The page of 1 has a next token")
        XCTAssertEqual(recorder.operations, ["ListWebAuthnCredentials", "ListWebAuthnCredentials"])
    }

    /// - Given: a fresh, signed-in user on the WebAuthn pool with no passkey
    /// - When:
    ///    - the user deletes a credential identifier Cognito has never issued
    /// - Then:
    ///    - Cognito's answer reaches the caller as `.service(.resourceNotFound)` after one
    ///      `DeleteWebAuthnCredential` request, and the session is still signed in, with an empty list
    func testDeletingACredentialThatDoesNotExistIsResourceNotFound() async throws {
        let recorder = RecordingHTTPClient()
        let client = try await signedInClient("wa-delete", recorder: recorder)
        let unknownId = Data((0 ..< 32).map { _ in UInt8.random(in: 0 ... 255) }).base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")

        do {
            try await client.deleteWebAuthnCredential(credentialId: unknownId)
            XCTFail("Deleting a credential that does not exist succeeded")
        } catch let error as AuthClientError {
            guard case .service(let code, _, _, _) = error else {
                return XCTFail("Expected .service(.resourceNotFound), got \(Self.caseName(error))")
            }
            XCTAssertEqual(code, .resourceNotFound)
        }

        XCTAssertEqual(recorder.operations, ["DeleteWebAuthnCredential"])
        let state = await client.currentSessionState()
        guard case .signedIn = state else {
            return XCTFail("The session is no longer signed in")
        }
        let page = try await client.listWebAuthnCredentials()
        XCTAssertTrue(page.credentials.isEmpty, "The list is not empty after the failed delete")
    }

    /// - Given: a fresh, signed-in user on the WebAuthn pool
    /// - When:
    ///    - the user lists with page sizes 0 and 21, then 20
    /// - Then:
    ///    - the first two throw `.validation(field: "pageSize")` and send nothing; 20, Cognito's maximum,
    ///      is sent and answered
    func testAPageSizeOutsideCognitosRangeSendsNothing() async throws {
        let recorder = RecordingHTTPClient()
        let client = try await signedInClient("wa-size", recorder: recorder)

        for pageSize: UInt in [0, 21] {
            do {
                _ = try await client.listWebAuthnCredentials(options: .init(pageSize: pageSize))
                XCTFail("Page size \(pageSize) was accepted")
            } catch let error as AuthClientError {
                guard case .validation(let field, _, _, _) = error else {
                    return XCTFail("Expected .validation, got \(Self.caseName(error))")
                }
                XCTAssertEqual(field, "pageSize")
            }
        }
        XCTAssertEqual(recorder.operations, [])

        _ = try await client.listWebAuthnCredentials(options: .init(pageSize: 20))
        XCTAssertEqual(recorder.operations, ["ListWebAuthnCredentials"])
    }

    /// - Given: a client on the WebAuthn pool whose session has never signed in
    /// - When:
    ///    - it lists and deletes
    /// - Then:
    ///    - both throw `.notSignedIn`, and no request reaches Cognito
    func testASignedOutSessionIsRefusedWithoutARequest() async throws {
        try SandboxPoolClient(.webAuthn).requireLive("web-authn")
        let recorder = RecordingHTTPClient()
        let client = try makeClient("wa-out", pool: .webAuthn, configureUserPoolClient: recorder.configureUserPoolClient)

        do {
            _ = try await client.listWebAuthnCredentials()
            XCTFail("A signed-out session listed credentials")
        } catch let error as AuthClientError {
            guard case .notSignedIn = error else {
                return XCTFail("Expected .notSignedIn, got \(Self.caseName(error))")
            }
        }
        do {
            try await client.deleteWebAuthnCredential(credentialId: "none")
            XCTFail("A signed-out session deleted a credential")
        } catch let error as AuthClientError {
            guard case .notSignedIn = error else {
                return XCTFail("Expected .notSignedIn, got \(Self.caseName(error))")
            }
        }
        XCTAssertEqual(recorder.operations, [])
    }

    // MARK: - Support

    /// A client on the WebAuthn pool with a fresh user signed in (SRP), and the recorder cleared of the
    /// sign-in's requests.
    private func signedInClient(_ tag: String, recorder: RecordingHTTPClient) async throws -> AmplifyCognitoClient {
        try SandboxPoolClient(.webAuthn).requireLive("web-authn")
        let user = try await makeFreshUser(on: .webAuthn)
        let password = try XCTUnwrap(user.password, "The fresh user has no password")
        let client = try makeClient(tag, pool: .webAuthn, configureUserPoolClient: recorder.configureUserPoolClient)
        let result = try await client.signIn(username: user.username, password: password)
        XCTAssertEqual(result.nextStep, .done)
        recorder.reset()
        return client
    }

    /// The error's case name only, so a failure message never carries a service message or an identifier.
    private static func caseName(_ error: AuthClientError) -> String {
        String(describing: error).prefix { $0 != "(" }.description
    }
}
