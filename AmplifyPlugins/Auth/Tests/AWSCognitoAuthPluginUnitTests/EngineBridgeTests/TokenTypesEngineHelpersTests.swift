//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import XCTest
@testable import AWSCognitoAuthPlugin
@testable import InternalAWSCognitoAuth

/// The helpers copied onto the engine's token and credential forks (`doesExpire(in:)`, the `expiresIn`
/// initializer) against the public types' originals, and the stored format beyond the stored-format golden
/// fixtures: the frozen payloads of the Cognito client's session record, and the rejected fixtures.
class TokenTypesEngineHelpersTests: XCTestCase {

    struct ClaimsCase {
        let idToken: String
        let accessToken: String
        let exp: TimeInterval
    }

    struct RelativeCase {
        let idToken: String
        let accessToken: String
        let expiresIn: Int?
    }

    // MARK: Copied helpers

    /// Test that the forks' expiry checks agree with the public types'
    ///
    /// - Given: Tokens whose `exp` claims are in the past, the near future and the far future, tokens
    ///   without an `exp` claim, malformed tokens, and credentials that expire at various times
    /// - When:
    ///    - `doesExpire(in:)` is called on the fork and the public type, with several buffers
    /// - Then:
    ///    - The results are the same
    ///
    func testDoesExpire_matchesThePublicTypes() {
        let now = Date().timeIntervalSince1970
        let tokenStrings = [
            TokenTypesBridgeTests.token(exp: now - 1_000),
            TokenTypesBridgeTests.token(exp: now + 60),
            TokenTypesBridgeTests.token(exp: now + 3_600),
            TokenTypesBridgeTests.token(exp: nil),
            "not-a-jwt",
            "a.b"
        ]
        var checked = 0
        for idToken in tokenStrings {
            for accessToken in tokenStrings {
                let engine = EngineUserPoolTokens(
                    idToken: idToken,
                    accessToken: accessToken,
                    refreshToken: "refresh",
                    expiration: Date()
                )
                let publicTokens = AWSCognitoUserPoolTokens(engine)
                for buffer: TimeInterval in [0, 120, 7_200] {
                    XCTAssertEqual(engine.doesExpire(in: buffer), publicTokens.doesExpire(in: buffer))
                    checked += 1
                }
            }
        }
        for offset: TimeInterval in [-1_000, 60, 3_600] {
            let engine = EngineAWSCredentials(
                accessKeyId: "a",
                secretAccessKey: "s",
                sessionToken: "t",
                expiration: Date(timeIntervalSinceNow: offset)
            )
            for buffer: TimeInterval in [0, 120, 7_200] {
                XCTAssertEqual(engine.doesExpire(in: buffer), AuthAWSCognitoCredentials(engine).doesExpire(in: buffer))
                checked += 1
            }
        }
        XCTAssertEqual(checked, 117)
    }

    /// Test that the fork's `expiresIn` initializer computes the expiration as the public type's does
    ///
    /// - Given: Token pairs where both, one or neither token has an `exp` claim, and explicit `expiresIn`
    ///   values
    /// - When:
    ///    - The fork and the public type's internal `init(idToken:accessToken:refreshToken:expiresIn:)` build
    ///      tokens from the same inputs
    /// - Then:
    ///    - Expirations taken from claims are identical; expirations relative to now differ only by the time
    ///      between the two calls
    ///
    func testExpiresInInit_matchesThePublicType() {
        let early = TokenTypesBridgeTests.token(exp: 1_900_000_000)
        let late = TokenTypesBridgeTests.token(exp: 2_000_000_000)
        let none = TokenTypesBridgeTests.token(exp: nil)
        let fromClaims = [
            ClaimsCase(idToken: early, accessToken: late, exp: 1_900_000_000),
            ClaimsCase(idToken: late, accessToken: early, exp: 1_900_000_000),
            ClaimsCase(idToken: none, accessToken: late, exp: 2_000_000_000),
            ClaimsCase(idToken: early, accessToken: none, exp: 1_900_000_000)
        ]
        for claimsCase in fromClaims {
            let (idToken, accessToken, exp) = (claimsCase.idToken, claimsCase.accessToken, claimsCase.exp)
            let noExpiresIn: Int? = nil
            let engine = EngineUserPoolTokens(idToken: idToken, accessToken: accessToken, refreshToken: "r", expiresIn: noExpiresIn)
            let publicTokens = AWSCognitoUserPoolTokens(idToken: idToken, accessToken: accessToken, refreshToken: "r", expiresIn: noExpiresIn)
            XCTAssertEqual(engine.expiration, Date(timeIntervalSince1970: exp))
            XCTAssertEqual(EngineUserPoolTokens(publicTokens), engine)
        }

        let relative = [
            RelativeCase(idToken: none, accessToken: none, expiresIn: nil),
            RelativeCase(idToken: early, accessToken: late, expiresIn: 300),
            RelativeCase(idToken: early, accessToken: late, expiresIn: -10_000)
        ]
        for relativeCase in relative {
            let (idToken, accessToken, expiresIn) = (relativeCase.idToken, relativeCase.accessToken, relativeCase.expiresIn)
            let engine = EngineUserPoolTokens(idToken: idToken, accessToken: accessToken, refreshToken: "r", expiresIn: expiresIn)
            let publicTokens = EngineUserPoolTokens(
                AWSCognitoUserPoolTokens(idToken: idToken, accessToken: accessToken, refreshToken: "r", expiresIn: expiresIn)
            )
            XCTAssertEqual(engine.expiration.timeIntervalSince1970, publicTokens.expiration.timeIntervalSince1970, accuracy: 5)
            XCTAssertEqual(engine.idToken, publicTokens.idToken)
            XCTAssertEqual(engine.accessToken, publicTokens.accessToken)
            XCTAssertEqual(engine.refreshToken, publicTokens.refreshToken)
        }
    }

    // MARK: Stored format beyond the golden fixtures

    /// Test that the frozen session-record payloads decode through the fork, and that what the fork writes
    /// is what a released plugin decodes
    ///
    /// - Given: The five frozen `AmplifyCredentials` payloads of the Cognito client's session record
    ///   (`TestResources/amplifyCredentials/*.payload.json`)
    /// - When:
    ///    - Each is decoded with the plugin's `AmplifyCredentials`, which holds the forks, and with the
    ///      pre-fork shape that holds the public types; each side's encoding is decoded by the other
    /// - Then:
    ///    - Both decode it to the same fields, which are the fixture's recorded values
    ///    - The fork's re-encoding is the frozen file's JSON tree, and the pre-fork shape decodes it
    ///
    func testFrozenSessionRecordPayloads_decodeThroughTheForkAndStayReadableByReleasedPlugins() throws {
        for caseName in AmplifyCredentialsPayloadFixtures.caseNames {
            let frozen = try AmplifyCredentialsPayloadFixtures.data(caseName)
            let (fork, _) = try StoredFormatForkCrossDecoders.crossDecode(
                frozen,
                fork: AmplifyCredentials.self,
                publicType: BaseShapeAmplifyCredentials.self
            )
            let expected = try XCTUnwrap(AmplifyCredentialsPayloadFixtures.expected(caseName), caseName)
            XCTAssertEqual(fork, expected, caseName)
            let written = try JSONEncoder().encode(fork)
            XCTAssertTrue(try CanonicalJSON.areEqual(written, frozen), caseName)
            XCTAssertNoThrow(try JSONDecoder().decode(BaseShapeAmplifyCredentials.self, from: written), caseName)
        }
    }

    /// Test that inputs rejected before the forks are still rejected, the same way, through the fork
    ///
    /// - Given: The stored-format must-throw fixtures for tokens and for whole sessions
    /// - When:
    ///    - Each is decoded with the fork-holding type and with the public-typed shape
    /// - Then:
    ///    - Both throw, with the same `DecodingError` case
    ///
    func testRejectedFixtures_areRejectedTheSameWayByForkAndPublicShape() throws {
        let tokens = try Self.goldenFixture("rejected-userPoolTokens-string-expiration")
        XCTAssertEqual(
            Self.decodingErrorCase(EngineUserPoolTokens.self, tokens),
            Self.decodingErrorCase(AWSCognitoUserPoolTokens.self, tokens)
        )
        XCTAssertEqual(Self.decodingErrorCase(EngineUserPoolTokens.self, tokens), "typeMismatch")

        let sessions = ["rejected-session-missing-username", "rejected-session-unknown-case", "rejected-session-unknown-provider"]
        for name in sessions {
            let data = try Self.goldenFixture(name)
            let fork = Self.decodingErrorCase(AmplifyCredentials.self, data)
            XCTAssertNotNil(fork, name)
            XCTAssertEqual(fork, Self.decodingErrorCase(BaseShapeAmplifyCredentials.self, data), name)
        }
    }

    static func goldenFixture(_ name: String) throws -> Data {
        try Data(contentsOf: GoldenFiles.directory("GoldenStoredFormat").appendingPathComponent("\(name).json"))
    }

    /// The `DecodingError` case decoding `data` as `type` throws, or `nil` if it decodes.
    static func decodingErrorCase(_ type: (some Decodable).Type, _ data: Data) -> String? {
        do {
            _ = try JSONDecoder().decode(type, from: data)
            return nil
        } catch let error as DecodingError {
            switch error {
            case .typeMismatch: return "typeMismatch"
            case .valueNotFound: return "valueNotFound"
            case .keyNotFound: return "keyNotFound"
            case .dataCorrupted: return "dataCorrupted"
            @unknown default: return "unknown"
            }
        } catch {
            return "\(error)"
        }
    }
}
