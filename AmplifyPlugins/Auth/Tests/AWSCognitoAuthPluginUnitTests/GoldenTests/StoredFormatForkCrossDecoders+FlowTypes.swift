//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import XCTest
@testable import Amplify
@testable import AWSCognitoAuthPlugin
@testable import InternalAWSCognitoAuth

/// The flow-type and provider entries of the stored-format gate's fork cross-decode hook
/// (`StoredFormatGoldenTests.forkCrossDecoders`): `EngineAuthFlowType` (with `EngineAuthFactorType` inside
/// it) against the public `AuthFlowType`, and `EngineAuthProvider` against `Amplify.AuthProvider`.
///
/// Every committed fixture whose name (after `permuted-` / `legacy-`) starts with one of the prefixes
/// below is searched for the persisted sub-values of these types:
/// - a whole `authFlowType-*` fixture;
/// - the value of every `"authFlowType"` key (`UserPoolConfigurationData`);
/// - `"apiBased"` → `"_0"` (`SignInMethod.apiBased`, which is how `SignedInData` and the sessions hold it);
/// - `"federatedToken"` → `"provider"` (`FederatedToken.provider`, the only persisted `AuthProvider`).
///
/// For each sub-value, `check` requires, throwing on the first difference:
/// 1. both the public type and the fork decode it (throwing decode, production decoder);
/// 2. the two decoded values dump to the same fields;
/// 3. the plugin's converters map each decoded value onto the other, `==` and field for field;
/// 4. the public and fork re-encodings are the same JSON tree;
/// 5. each type decodes the other's encoding to the same fields (public → fork and fork → public).
@available(*, deprecated, message: "Exercises the deprecated AuthFlowType.custom, on purpose")
extension StoredFormatGoldenTests {

    static var flowTypeForkCrossDecoders: [ForkCrossDecoder] {
        [
            .init(fixturePrefix: "authFlowType-") { try ForkCrossCheck.flows(in: $0, root: true) },
            .init(fixturePrefix: "signInMethod-apiBased-") { try ForkCrossCheck.flows(in: $0) },
            .init(fixturePrefix: "userPoolConfiguration-") { try ForkCrossCheck.flows(in: $0) },
            .init(fixturePrefix: "authConfiguration-userPools") { try ForkCrossCheck.flows(in: $0) },
            .init(fixturePrefix: "session-userPool") { try ForkCrossCheck.flows(in: $0) },
            .init(fixturePrefix: "signedInData-") { try ForkCrossCheck.flows(in: $0, required: false) },
            .init(fixturePrefix: "session-identityPoolWithFederation-") { try ForkCrossCheck.providers(in: $0) }
        ]
    }
}

@available(*, deprecated, message: "Exercises the deprecated AuthFlowType.custom, on purpose")
enum ForkCrossCheck {

    struct Mismatch: Error, CustomStringConvertible {
        let description: String
    }

    /// Cross-checks every persisted flow type in `fixture`. `root`: the fixture is the flow type itself.
    /// `required`: the fixture must hold at least one.
    static func flows(in fixture: Data, root: Bool = false, required: Bool = true) throws {
        let values = try root ? [fixture] : subvalues(in: fixture, of: .flowType)
        if required, values.isEmpty {
            throw Mismatch(description: "no persisted authFlowType in the fixture")
        }
        for value in values {
            try check(
                value,
                public: AuthFlowType.self,
                fork: EngineAuthFlowType.self,
                toFork: { EngineAuthFlowType($0) },
                toPublic: { AuthFlowType($0) }
            )
        }
    }

    /// Cross-checks every persisted `FederatedToken.provider` in `fixture`.
    static func providers(in fixture: Data) throws {
        let values = try subvalues(in: fixture, of: .provider)
        if values.isEmpty {
            throw Mismatch(description: "no persisted federatedToken.provider in the fixture")
        }
        for value in values {
            try check(
                value,
                public: AuthProvider.self,
                fork: EngineAuthProvider.self,
                toFork: { EngineAuthProvider($0) },
                toPublic: { AuthProvider($0) }
            )
        }
    }

    static func check<Public: Codable & Equatable, Fork: Codable & Equatable>(
        _ data: Data,
        public: Public.Type,
        fork: Fork.Type,
        toFork: (Public) -> Fork,
        toPublic: (Fork) -> Public
    ) throws {
        let text = CanonicalJSON.string(data)
        func require(_ condition: Bool, _ what: String) throws {
            if !condition {
                throw Mismatch(description: "\(text): \(what)")
            }
        }

        // 1. Both decode.
        let publicValue = try StoredFormatFixture.productionDecode(Public.self, data)
        let forkValue = try StoredFormatFixture.productionDecode(Fork.self, data)

        // 2. Same fields.
        let fields = FieldDump.fields(of: publicValue)
        try require(FieldDump.fields(of: forkValue) == fields, "fork decodes to \(FieldDump.fields(of: forkValue)), public to \(fields)")

        // 3. The converters agree with decoding, both ways.
        try require(toFork(publicValue) == forkValue, "converting the public value does not give the fork's")
        try require(toPublic(forkValue) == publicValue, "converting the fork value does not give the public one")
        try require(FieldDump.fields(of: toFork(publicValue)) == fields, "converted public value dumps differently")
        try require(FieldDump.fields(of: toPublic(forkValue)) == fields, "converted fork value dumps differently")

        // 4. Same JSON tree.
        let publicEncoded = try StoredFormatFixture.productionEncode(publicValue)
        let forkEncoded = try StoredFormatFixture.productionEncode(forkValue)
        try require(
            CanonicalJSON.areEqual(publicEncoded, forkEncoded),
            "public encodes as \(CanonicalJSON.string(publicEncoded)), fork as \(CanonicalJSON.string(forkEncoded))"
        )

        // 5. Cross-decode, both directions. The reference is each type decoding its own encoding, not the
        // fixture's value: a bare legacy "custom" decodes as `.custom`, which re-encodes as
        // `CUSTOM_AUTH_WITH_SRP` and so reads back as `.customWithSRP`, in both types.
        let publicRoundTrip = try FieldDump.fields(of: StoredFormatFixture.productionDecode(Public.self, publicEncoded))
        let forkRoundTrip = try FieldDump.fields(of: StoredFormatFixture.productionDecode(Fork.self, forkEncoded))
        let forkFromPublic = try StoredFormatFixture.productionDecode(Fork.self, publicEncoded)
        let publicFromFork = try StoredFormatFixture.productionDecode(Public.self, forkEncoded)
        try require(forkRoundTrip == publicRoundTrip, "the fork reads its own encoding back as \(forkRoundTrip), the public type \(publicRoundTrip)")
        try require(FieldDump.fields(of: forkFromPublic) == publicRoundTrip, "fork decodes the public encoding differently")
        try require(FieldDump.fields(of: publicFromFork) == forkRoundTrip, "public decodes the fork encoding differently")
    }

    enum Kind {
        case flowType
        case provider
    }

    /// The persisted sub-values of one kind, each re-serialized on its own (fragments allowed, because a
    /// pre-passwordless flow type is a bare string).
    static func subvalues(in fixture: Data, of kind: Kind) throws -> [Data] {
        var found: [Any] = []
        func walk(_ value: Any) {
            if let object = value as? [String: Any] {
                for (key, child) in object {
                    switch (kind, key) {
                    case (.flowType, "authFlowType"):
                        found.append(child)
                    case (.flowType, "apiBased"):
                        if let payload = (child as? [String: Any])?["_0"] {
                            found.append(payload)
                        }
                    case (.provider, "federatedToken"):
                        if let provider = (child as? [String: Any])?["provider"] {
                            found.append(provider)
                        }
                    default:
                        break
                    }
                    walk(child)
                }
            } else if let array = value as? [Any] {
                array.forEach(walk)
            }
        }
        try walk(JSONSerialization.jsonObject(with: fixture, options: [.fragmentsAllowed]))
        return try found.map {
            try JSONSerialization.data(withJSONObject: $0, options: [.fragmentsAllowed, .withoutEscapingSlashes])
        }
    }
}
