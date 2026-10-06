//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import InternalAWSCognitoAuth
import XCTest
@_spi(AmplifyExperimental) @testable import AmplifyCognitoClient

/// The live engine's pure reads over the real engine types, and the payload contract: every
/// frozen `*.payload.json` fixture, which the released plugin reads, decodes through the client's adapter.
final class LiveSessionEngineTests: XCTestCase {

    private var engine: LiveSessionEngine!

    override func setUpWithError() throws {
        try super.setUpWithError()
        let keychain = TestKeychain()
        engine = try LiveSessionEngine(resources: EngineResources(
            authConfiguration: AuthConfiguration(client: ClientFixtures.configuration),
            clients: CognitoServiceClients(configuration: ClientFixtures.configuration, configureUserPoolClient: nil),
            devices: DeviceRecordIO(store: keychain.deviceStore(for: StorageFixtures.namespace)),
            analytics: LazyUserPoolAnalytics(pinpointAppId: nil)
        ))
    }

    override func tearDown() {
        engine = nil
        super.tearDown()
    }

    // MARK: The frozen payloads

    /// Every frozen payload decodes through the adapter's `describe`
    ///
    /// - Given: the five frozen payload fixtures the plugin wrote, read in place
    /// - When:
    ///    - each is described by the live engine
    /// - Then:
    ///    - each yields its kind, username, `sub` and identity ID; the federated one has no user
    ///
    func testEveryFrozenPayloadIsDescribed() throws {
        for caseName in EnginePayloadFixtures.caseNames {
            let summary = try engine.describe(EnginePayloadFixtures.data(caseName))
            XCTAssertEqual(summary, EnginePayloadFixtures.expectedSummary(caseName), caseName)
        }
        let federated = try engine.describe(EnginePayloadFixtures.data("identityPoolWithFederation"))
        XCTAssertNil(federated.user)
        XCTAssertEqual(
            try engine.describe(EnginePayloadFixtures.data("userPoolOnly")).user,
            AuthClientUser(username: "fixture-user", userId: "fixture-sub")
        )
    }

    /// The adapter writes the payload format it reads: re-encoding a fixture gives the fixture's tree.
    ///
    /// - Given: the five frozen payloads
    /// - When:
    ///    - each is decoded and re-encoded with the credential slot's coder, the plugin store's
    /// - Then:
    ///    - the re-encoded JSON tree equals the fixture's (compared as trees: the bytes are not deterministic),
    ///      so what the client commits stays readable by the released plugin
    ///
    func testEveryFrozenPayloadRoundTripsToTheSameTree() throws {
        for caseName in EnginePayloadFixtures.caseNames {
            let fixture = try EnginePayloadFixtures.data(caseName)
            let reencoded = try CredentialSlot.encode(CredentialSlot.decode(fixture))
            XCTAssertEqual(try Self.tree(reencoded), try Self.tree(fixture), caseName)
        }
    }

    // MARK: The other pure reads

    /// The AWS credentials, access token and user pool tokens are read from each kind that has them.
    ///
    /// - Given: the five frozen payloads
    /// - When:
    ///    - the live engine reads each one's AWS credentials, access token and user pool tokens
    /// - Then:
    ///    - the kinds with an identity pool have the fixture's AWS credentials, and the others none; the two
    ///      user pool kinds have the fixture's tokens, and the others none
    ///
    func testCredentialsAndTokensAreReadPerKind() throws {
        let tokens = AuthClientUserPoolTokens(
            idToken: EnginePayloadFixtures.token,
            accessToken: EnginePayloadFixtures.token,
            refreshToken: EnginePayloadFixtures.refreshToken
        )
        let rows: [(String, hasAWSCredentials: Bool, hasTokens: Bool)] = [
            ("userPoolOnly", false, true),
            ("userPoolAndIdentityPool", true, true),
            ("identityPoolOnly", true, false),
            ("identityPoolWithFederation", true, false),
            ("noCredentials", false, false)
        ]
        for (caseName, hasAWSCredentials, hasTokens) in rows {
            let payload = try EnginePayloadFixtures.data(caseName)
            XCTAssertEqual(try engine.awsCredentials(in: payload), hasAWSCredentials ? EnginePayloadFixtures.awsCredentials : nil, caseName)
            XCTAssertEqual(try engine.accessToken(in: payload), hasTokens ? EnginePayloadFixtures.token : nil, caseName)
            XCTAssertEqual(try engine.userPoolTokens(in: payload), hasTokens ? tokens : nil, caseName)
        }
    }

    /// Whether a payload needs a refresh is measured from the given instant, with the engine's buffer.
    ///
    /// - Given: the five frozen payloads, which all expire at the same instant
    /// - When:
    ///    - `needsRefresh` is asked well before, just outside and just inside the two-minute buffer, and after
    /// - Then:
    ///    - a payload with credentials needs a refresh only inside the buffer or after; `noCredentials` always does
    ///
    func testNeedsRefreshUsesTheGivenInstant() throws {
        let expiry = EnginePayloadFixtures.expiry
        let instants: [(Date, Bool)] = [
            (expiry.addingTimeInterval(-86_400), false),
            (expiry.addingTimeInterval(-121), false),
            (expiry.addingTimeInterval(-119), true),
            (expiry.addingTimeInterval(1), true)
        ]
        for caseName in EnginePayloadFixtures.caseNames {
            let payload = try EnginePayloadFixtures.data(caseName)
            for (instant, needsRefreshWithCredentials) in instants {
                let expected = caseName == "noCredentials" ? true : needsRefreshWithCredentials
                XCTAssertEqual(try engine.needsRefresh(payload, at: instant), expected, "\(caseName) at \(instant)")
            }
        }
    }

    /// A payload the engine cannot read reaches the core as the client's `unknown`, never an engine type.
    ///
    /// - Given: bytes that are not a credentials payload
    /// - When:
    ///    - the core reads them through each checked wrapper
    /// - Then:
    ///    - each throws `AuthClientError.unknown`, with the decoding error underneath
    ///
    func testAnUnreadablePayloadIsTheClientsUnknown() {
        let payload = Data(#"{"notACase":{}}"#.utf8)
        let reads: [(String, () throws -> Void)] = [
            ("describe", { _ = try self.engine.checkedDescribe(payload) }),
            ("awsCredentials", { _ = try self.engine.checkedAWSCredentials(in: payload) }),
            ("accessToken", { _ = try self.engine.checkedAccessToken(in: payload) }),
            ("userPoolTokens", { _ = try self.engine.checkedUserPoolTokens(in: payload) }),
            ("needsRefresh", { _ = try self.engine.checkedNeedsRefresh(payload, at: Date()) })
        ]
        for (name, read) in reads {
            XCTAssertThrowsError(try read(), name) { error in
                guard case .unknown(_, _, let underlying) = error as? AuthClientError else {
                    return XCTFail("\(name) threw \(error)")
                }
                XCTAssertTrue(underlying is DecodingError, name)
            }
        }
    }

    private static func tree(_ data: Data) throws -> NSObject {
        try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? NSObject)
    }
}
