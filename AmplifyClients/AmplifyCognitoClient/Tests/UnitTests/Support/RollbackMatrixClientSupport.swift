//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AmplifyKeychainTestCommon
import AWSCognitoIdentityProvider
import Foundation
import InternalAmplifyKeychain
import InternalAWSCognitoAuth
import XCTest

/// The plugin binaries the client's half of the rollback matrix rolls back to, as the plugin's half names them
/// (`RollbackMatrixTestSupport.swift` in the plugin's unit tests, which this target cannot import).
enum RollbackPluginBinary: String, CaseIterable {
    /// A released plugin (2.62.0), which does not know the Cognito client's records, the `amplify.<digits>.`
    /// accounts. Its view (`PluginBinaryKeychainView`) refuses any read of one, a guard on the emulation: 2.62.0 never
    /// asks. On every read, save, delete and refresh path it runs the same code as `.current`; only the access-group
    /// transition rows differ.
    case released
    /// This plugin, over the whole keychain. It no longer reads the client's records either.
    case current

    /// The keychain as this binary's credential store sees it, over `base`. Every read of a client record either way
    /// is recorded in `hiddenReads`.
    func keychainStore(over base: any KeychainItemStoreBehavior, recording hiddenReads: HiddenReads) -> any KeychainItemStoreBehavior {
        PluginBinaryKeychainView(base: base, hidesClientRecords: self == .released, onClientRecordRead: { hiddenReads.record($0) })
    }
}

/// The client records a plugin binary asked to read, which the rows assert stays empty.
///
/// - Note: `@unchecked Sendable`: `recorded` is only touched while holding `lock`.
final class HiddenReads: @unchecked Sendable {
    private let lock = NSLock()
    private var recorded: [String] = []

    var accounts: [String] {
        lock.withLock { recorded }
    }

    func record(_ account: String) {
        lock.withLock { recorded.append(account) }
    }
}

/// Cognito's side of refresh-token rotation for one login, shared by every binary a row runs: the one refresh token
/// it accepts now. A refresh with it succeeds and rotates it; any other is refused with
/// `RefreshTokenReuseException`, as Cognito refuses a refresh token rotated away.
///
/// - Note: `@unchecked Sendable`: the properties below are only touched while holding `lock`.
final class RotatingRefreshTokens: @unchecked Sendable {

    private let lock = NSLock()
    private var live: String
    private var sentTokens: [String] = []
    private var refusedTokens: [String] = []

    init(live: String) {
        self.live = live
    }

    /// Every refresh token sent, in order.
    var sent: [String] {
        lock.withLock { sentTokens }
    }

    /// Every refresh token refused, in order.
    var refused: [String] {
        lock.withLock { refusedTokens }
    }

    /// Answers a refresh of `username`'s login with tokens of `version`, rotating the live token to `next`.
    func refresh(
        _ input: GetTokensFromRefreshTokenInput,
        username: String = "alice",
        version: Int = 2,
        rotatingTo next: String
    ) throws -> GetTokensFromRefreshTokenOutput {
        try lock.withLock {
            let token = input.refreshToken ?? ""
            sentTokens.append(token)
            guard token == live else {
                refusedTokens.append(token)
                throw AWSCognitoIdentityProvider.RefreshTokenReuseException(message: "Refresh token has been used")
            }
            live = next
        }
        return GetTokensFromRefreshTokenOutput(authenticationResult: LiveEngineFixtures.tokens(username, version: version, refreshToken: next))
    }
}

/// The plugin's committed test resources, read from the source tree, as the plugin's own golden tests read them.
enum PluginTestResources {

    static func url(_ path: String) -> URL {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent() // Support
            .deletingLastPathComponent() // UnitTests
            .deletingLastPathComponent() // Tests
            .deletingLastPathComponent() // AmplifyCognitoClient
            .deletingLastPathComponent() // AmplifyClients
            .deletingLastPathComponent() // repository root
            .appendingPathComponent("AmplifyPlugins/Auth/Tests/AWSCognitoAuthPluginUnitTests/TestResources")
            .appendingPathComponent(path)
    }

    /// A G2 stored-format golden (`GoldenStoredFormat/<name>`), without the trailing newline the file ends with.
    static func goldenStoredFormat(_ name: String) throws -> Data {
        var data = try Data(contentsOf: url("GoldenStoredFormat/\(name)"))
        if data.last == UInt8(ascii: "\n") {
            data.removeLast()
        }
        return data
    }
}
