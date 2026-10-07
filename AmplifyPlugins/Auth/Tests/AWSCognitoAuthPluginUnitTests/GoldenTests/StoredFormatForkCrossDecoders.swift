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

/// The public ↔ fork cross-decoders of the engine's token and credential forks, registered in
/// `StoredFormatGoldenTests.forkCrossDecoders`.
///
/// - `userPoolTokens` / `awsCredentials`: the fixtures of the public types, which still exist, are decoded
///   with both the public type and the fork.
/// - `signedInData-` / `session-`: `SignedInData` and `AmplifyCredentials` hold the forks, so
///   the plugin's own types *are* the forked path. The public-typed side is `BaseShapeSignedInData` /
///   `BaseShapeAmplifyCredentials`: the declarations from before the forks, with the public token and
///   credential types, so the check is against the shape a released plugin decodes. The `SignInMethod` and
///   `FederatedToken` they name hold the engine flow and provider types too, so for those fields this is
///   fork against fork; the flow and provider values are checked against the public types by
///   `flowTypeForkCrossDecoders`, registered beside these.
///
/// For every matching fixture, each check requires:
/// 1. both sides decode it, to the same fields;
/// 2. each side's encoding decodes with the other side, to the fields that side gets from its own
///    encoding (both directions);
/// 3. the two encodings are the same JSON tree;
/// 4. for the token and credential types, the converters map each decoded value onto the other exactly.
enum StoredFormatForkCrossDecoders {

    @available(*, deprecated, message: "Registers with StoredFormatGoldenTests, which is deprecated on purpose")
    static var all: [StoredFormatGoldenTests.ForkCrossDecoder] {
        [
            .init(fixturePrefix: "userPoolTokens") { fixture in
                let (fork, publicValue) = try crossDecode(
                    fixture,
                    fork: EngineUserPoolTokens.self,
                    publicType: AWSCognitoUserPoolTokens.self
                )
                try require(EngineUserPoolTokens(publicValue) == fork, "EngineUserPoolTokens(_:) changed the value")
                try require(AWSCognitoUserPoolTokens(fork) == publicValue, "AWSCognitoUserPoolTokens(_:) changed the value")
            },
            .init(fixturePrefix: "awsCredentials") { fixture in
                let (fork, publicValue) = try crossDecode(
                    fixture,
                    fork: EngineAWSCredentials.self,
                    publicType: AuthAWSCognitoCredentials.self
                )
                try require(EngineAWSCredentials(publicValue) == fork, "EngineAWSCredentials(_:) changed the value")
                try require(AuthAWSCognitoCredentials(fork) == publicValue, "AuthAWSCognitoCredentials(_:) changed the value")
            },
            .init(fixturePrefix: "signedInData-") { fixture in
                _ = try crossDecode(fixture, fork: SignedInData.self, publicType: BaseShapeSignedInData.self)
            },
            .init(fixturePrefix: "session-") { fixture in
                _ = try crossDecode(fixture, fork: AmplifyCredentials.self, publicType: BaseShapeAmplifyCredentials.self)
            }
        ]
    }

    struct Mismatch: Error, CustomStringConvertible {
        let description: String
    }

    static func require(_ condition: Bool, _ message: @autoclosure () -> String) throws {
        if !condition {
            throw Mismatch(description: message())
        }
    }

    /// Runs checks 1–3 and returns both decoded values.
    @discardableResult
    static func crossDecode<Fork: Codable, Public: Codable>(
        _ data: Data,
        fork: Fork.Type,
        publicType: Public.Type
    ) throws -> (Fork, Public) {
        let decoder = JSONDecoder()
        let encoder = JSONEncoder()

        let forkValue = try decoder.decode(Fork.self, from: data)
        let publicValue = try decoder.decode(Public.self, from: data)
        let forkFields = FieldDump.fields(of: forkValue)
        try requireFields(FieldDump.fields(of: publicValue), forkFields, "public decode vs fork decode")

        // A re-encode can be lossy by design (`AuthFlowType.custom` is written as `customWithSRP`), so
        // each cross-decode is compared with the same side's decode of its own re-encoding.
        let forkEncoded = try encoder.encode(forkValue)
        let publicEncoded = try encoder.encode(publicValue)
        try requireFields(
            FieldDump.fields(of: decoder.decode(Public.self, from: forkEncoded)),
            FieldDump.fields(of: decoder.decode(Public.self, from: publicEncoded)),
            "the fork's encoding, decoded by the public type"
        )
        try requireFields(
            FieldDump.fields(of: decoder.decode(Fork.self, from: publicEncoded)),
            FieldDump.fields(of: decoder.decode(Fork.self, from: forkEncoded)),
            "the public type's encoding, decoded by the fork"
        )
        try require(
            CanonicalJSON.areEqual(forkEncoded, publicEncoded),
            "encodings differ:\n\(CanonicalJSON.string(forkEncoded))\n\(CanonicalJSON.string(publicEncoded))"
        )
        return (forkValue, publicValue)
    }

    static func requireFields(_ actual: [String: String], _ expected: [String: String], _ context: String) throws {
        guard actual != expected else { return }
        let paths = Set(actual.keys).union(expected.keys).sorted()
        let differences = paths.compactMap { path -> String? in
            actual[path] == expected[path] ? nil
                : "  \(path): expected \(expected[path] ?? "<absent>"), got \(actual[path] ?? "<absent>")"
        }
        throw Mismatch(description: "\(context):\n\(differences.joined(separator: "\n"))")
    }
}

/// `SignedInData` as it was declared before the token forks (`StateMachine/CodeGen/Data/SignedInData.swift`
/// on `main`): the same stored properties, in the same order, with the public `AWSCognitoUserPoolTokens`, and
/// the same synthesized `Codable`. The shape a released plugin decodes.
struct BaseShapeSignedInData: Codable {
    let userId: String
    let username: String
    let signedInDate: Date
    let signInMethod: SignInMethod
    let deviceMetadata: DeviceMetadata
    let cognitoUserPoolTokens: AWSCognitoUserPoolTokens
    var isRefreshTokenExpired: Bool?
    let inputUsername: String?
}

/// `AmplifyCredentials` as it was declared before the token forks (`CredentialStorage/AmplifyCredentials.swift`
/// on `main`): the same cases and labels, with the public `AuthAWSCognitoCredentials`, and the same
/// synthesized `Codable`. The shape a released plugin decodes, including the one inside the Cognito
/// client's session record.
enum BaseShapeAmplifyCredentials: Codable {

    case userPoolOnly(signedInData: BaseShapeSignedInData)

    case identityPoolOnly(
        identityID: String,
        credentials: AuthAWSCognitoCredentials
    )

    case identityPoolWithFederation(
        federatedToken: FederatedToken,
        identityID: String,
        credentials: AuthAWSCognitoCredentials
    )

    case userPoolAndIdentityPool(
        signedInData: BaseShapeSignedInData,
        identityID: String,
        credentials: AuthAWSCognitoCredentials
    )

    case noCredentials
}
