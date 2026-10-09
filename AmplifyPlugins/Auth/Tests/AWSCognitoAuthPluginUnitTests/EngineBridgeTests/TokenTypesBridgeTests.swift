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

/// The engine's token and credential forks (`EngineUserPoolTokens`, `EngineAWSCredentials`)
/// against the public types they copy, and the plugin's converters between them
/// (`Support/EngineBridge/`).
///
/// The stored-format side (every stored-format fixture decoded by both, in both directions) is in
/// `GoldenTests/StoredFormatForkCrossDecoders.swift`. This file covers the converters, equality and debug
/// output; `TokenTypesEngineHelpersTests` covers the copied helpers and the frozen session-record payloads.
class TokenTypesBridgeTests: XCTestCase {

    // MARK: Values

    /// `{"sub":"s","username":"u","exp":<exp>}`, unsigned.
    static func token(exp: TimeInterval?) -> String {
        var claims = ["sub": "bridge-sub", "username": "bridge-user"]
        if let exp {
            claims["exp"] = String(exp)
        }
        return CognitoAuthTestHelper.buildToken(for: claims)
    }

    static let engineTokens: [EngineUserPoolTokens] = [
        EngineUserPoolTokens(
            idToken: "id",
            accessToken: "access",
            refreshToken: "refresh",
            expiration: Date(timeIntervalSince1970: 1_700_003_600.25)
        ),
        EngineUserPoolTokens(idToken: "", accessToken: "", refreshToken: "", expiration: .distantPast),
        EngineUserPoolTokens(
            idToken: token(exp: 2_000_000_000),
            accessToken: token(exp: 2_000_000_001),
            refreshToken: "a-much-longer-refresh-token-value",
            expiration: .distantFuture
        ),
        EngineUserPoolTokens(
            idToken: "id",
            accessToken: "access",
            refreshToken: "refresh",
            expiration: Date(timeIntervalSinceReferenceDate: -0.5)
        )
    ]

    static let engineCredentials: [EngineAWSCredentials] = [
        EngineAWSCredentials(
            accessKeyId: "AKID",
            secretAccessKey: "secret/with+chars=",
            sessionToken: "session",
            expiration: Date(timeIntervalSince1970: 1_700_007_200.75)
        ),
        EngineAWSCredentials(accessKeyId: "", secretAccessKey: "", sessionToken: "", expiration: .distantPast),
        EngineAWSCredentials(
            accessKeyId: "AKID",
            secretAccessKey: "secret",
            sessionToken: "session",
            expiration: .distantFuture
        )
    ]

    // MARK: Converters

    /// Test that the token converters keep every stored property, in both directions
    ///
    /// - Given: Engine tokens with fractional, distant and negative expirations, and empty strings
    /// - When:
    ///    - Each is converted to the public type and back
    /// - Then:
    ///    - The public value has the same fields, and the round trip gives an equal engine value. The public
    ///      value converted back and forth is equal to itself too
    ///
    func testTokenConversion_isLosslessInBothDirections() {
        for engine in Self.engineTokens {
            let publicTokens = AWSCognitoUserPoolTokens(engine)
            XCTAssertEqual(FieldDump.fields(of: publicTokens), FieldDump.fields(of: engine))
            XCTAssertEqual(EngineUserPoolTokens(publicTokens), engine)
            XCTAssertEqual(AWSCognitoUserPoolTokens(EngineUserPoolTokens(publicTokens)), publicTokens)
        }
    }

    /// Test that the credential converters keep every stored property, in both directions
    ///
    /// - Given: Engine credentials with fractional and distant expirations, and empty strings
    /// - When:
    ///    - Each is converted to the public type and back
    /// - Then:
    ///    - The public value has the same fields, and both round trips give equal values
    ///
    func testCredentialConversion_isLosslessInBothDirections() {
        for engine in Self.engineCredentials {
            let publicCredentials = AuthAWSCognitoCredentials(engine)
            XCTAssertEqual(FieldDump.fields(of: publicCredentials), FieldDump.fields(of: engine))
            XCTAssertEqual(EngineAWSCredentials(publicCredentials), engine)
            XCTAssertEqual(AuthAWSCognitoCredentials(EngineAWSCredentials(publicCredentials)), publicCredentials)
        }
    }

    /// Test that the forks declare the public types' stored properties, in order
    ///
    /// - Given: One value of each fork and its public counterpart
    /// - When:
    ///    - Their stored properties are listed by reflection, each under its encoded key
    /// - Then:
    ///    - The names and order are the same
    ///
    func testForks_haveThePublicTypesStoredProperties() throws {
        let tokens = try XCTUnwrap(Self.engineTokens.first)
        let credentials = try XCTUnwrap(Self.engineCredentials.first)
        XCTAssertEqual(Self.labels(tokens), ["idToken", "accessToken", "refreshToken", "expiration"])
        XCTAssertEqual(Self.labels(tokens), Self.labels(AWSCognitoUserPoolTokens(tokens)))
        XCTAssertEqual(Self.labels(credentials), ["accessKeyId", "secretAccessKey", "sessionToken", "expiration"])
        XCTAssertEqual(Self.labels(credentials), Self.labels(AuthAWSCognitoCredentials(credentials)))
    }

    /// The stored properties' names, each as its encoded key (`FieldDump.recordedName(of:in:)`), so a public
    /// type whose property was renamed under an unchanged key still matches its fork.
    static func labels(_ value: Any) -> [String] {
        Mirror(reflecting: value).children.compactMap(\.label).map { FieldDump.recordedName(of: $0, in: type(of: value)) }
    }

    // MARK: Equality

    /// Test that fork equality is the public types' equality
    ///
    /// - Given: Pairs of values that are equal, or differ in exactly one stored property
    /// - When:
    ///    - The pairs are compared as forks and as public values
    /// - Then:
    ///    - Both comparisons agree for every pair
    ///
    func testForkEquality_matchesPublicEquality() {
        let base = Self.engineTokens[0]
        let tokenVariants = [
            base,
            EngineUserPoolTokens(idToken: "x", accessToken: base.accessToken, refreshToken: base.refreshToken, expiration: base.expiration),
            EngineUserPoolTokens(idToken: base.idToken, accessToken: "x", refreshToken: base.refreshToken, expiration: base.expiration),
            EngineUserPoolTokens(idToken: base.idToken, accessToken: base.accessToken, refreshToken: "x", expiration: base.expiration),
            EngineUserPoolTokens(
                idToken: base.idToken,
                accessToken: base.accessToken,
                refreshToken: base.refreshToken,
                expiration: base.expiration.addingTimeInterval(0.001)
            )
        ]
        for lhs in tokenVariants {
            for rhs in tokenVariants {
                XCTAssertEqual(lhs == rhs, AWSCognitoUserPoolTokens(lhs) == AWSCognitoUserPoolTokens(rhs))
            }
        }

        let credentials = Self.engineCredentials[0]
        let credentialVariants = [
            credentials,
            EngineAWSCredentials(
                accessKeyId: "x",
                secretAccessKey: credentials.secretAccessKey,
                sessionToken: credentials.sessionToken,
                expiration: credentials.expiration
            ),
            EngineAWSCredentials(
                accessKeyId: credentials.accessKeyId,
                secretAccessKey: "x",
                sessionToken: credentials.sessionToken,
                expiration: credentials.expiration
            ),
            EngineAWSCredentials(
                accessKeyId: credentials.accessKeyId,
                secretAccessKey: credentials.secretAccessKey,
                sessionToken: "x",
                expiration: credentials.expiration
            ),
            EngineAWSCredentials(
                accessKeyId: credentials.accessKeyId,
                secretAccessKey: credentials.secretAccessKey,
                sessionToken: credentials.sessionToken,
                expiration: credentials.expiration.addingTimeInterval(0.001)
            )
        ]
        for lhs in credentialVariants {
            for rhs in credentialVariants {
                XCTAssertEqual(lhs == rhs, AuthAWSCognitoCredentials(lhs) == AuthAWSCognitoCredentials(rhs))
            }
        }
        XCTAssertEqual(tokenVariants.count * credentialVariants.count, 25)
    }

    // MARK: Debug output (log lines print these values)

    /// Test that the forks print exactly what the public types print
    ///
    /// - Given: Every sample token and credential value
    /// - When:
    ///    - Each is printed as a fork and as the public type: `debugDescription`, `String(describing:)`,
    ///      `String(reflecting:)`, and inside a debug dictionary as `SignedInData` prints it
    /// - Then:
    ///    - The output is the same, so log lines that interpolate these values do not change. The prints
    ///      are Swift dictionaries, whose entry order is the hash order of each dictionary instance and so
    ///      differs between two equal dictionaries, even for the public type printed twice. Entries are
    ///      compared in key order (`SwiftCollectionPrint`); keys, values, masking and every other
    ///      character must match
    ///
    func testForkDebugOutput_matchesThePublicTypes() {
        for engine in Self.engineTokens {
            let publicTokens = AWSCognitoUserPoolTokens(engine)
            assertSamePrint(engine.debugDescription, publicTokens.debugDescription)
            assertSamePrint(String(describing: engine), String(describing: publicTokens))
            assertSamePrint(String(reflecting: engine), String(reflecting: publicTokens))
            assertSamePrint(
                (["tokens": engine] as [String: Any]).debugDescription,
                (["tokens": publicTokens] as [String: Any]).debugDescription
            )
            XCTAssertEqual(
                Self.sortedDescription(engine.debugDictionary),
                Self.sortedDescription(publicTokens.debugDictionary)
            )
        }
        for engine in Self.engineCredentials {
            let publicCredentials = AuthAWSCognitoCredentials(engine)
            assertSamePrint(engine.debugDescription, publicCredentials.debugDescription)
            assertSamePrint(String(describing: engine), String(describing: publicCredentials))
            assertSamePrint(String(reflecting: engine), String(reflecting: publicCredentials))
            XCTAssertEqual(
                Self.sortedDescription(engine.debugDictionary),
                Self.sortedDescription(publicCredentials.debugDictionary)
            )
        }
    }

    /// Equal once the entries of every printed dictionary are in key order.
    private func assertSamePrint(
        _ fork: String,
        _ publicType: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        XCTAssertEqual(
            SwiftCollectionPrint.sortingDictionaryKeys(fork),
            SwiftCollectionPrint.sortingDictionaryKeys(publicType),
            file: file,
            line: line
        )
    }

    static func sortedDescription(_ dictionary: [String: Any]) -> [String] {
        dictionary.map { "\($0.key)=\(String(reflecting: $0.value))" }.sorted()
    }
}
