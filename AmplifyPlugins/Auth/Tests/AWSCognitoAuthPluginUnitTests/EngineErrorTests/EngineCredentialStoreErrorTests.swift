//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import InternalAmplifyKeychain
import Security
import XCTest
@_spi(KeychainStore) @testable import AWSPluginsCore
@testable import AWSCognitoAuthPlugin
@testable import InternalAWSCognitoAuth

/// `EngineCredentialStoreError` against `KeychainStoreError`, the type it copies, and the
/// plugin boundary between them (`EngineBridge/KeychainStoreError+Engine.swift`).
final class EngineCredentialStoreErrorTests: XCTestCase {

    struct SentinelError: Error, Equatable {
        let tag: String
    }

    // MARK: Fixtures

    /// The same value as the engine's copy and as the public type.
    struct Pair<Engine, Plugin> {
        let label: String
        let engine: Engine
        let plugin: Plugin

        init(_ label: String, _ engine: Engine, _ plugin: Plugin) {
            self.label = label
            self.engine = engine
            self.plugin = plugin
        }
    }

    /// The statuses the text depends on: the classified ones, including the macOS entitlement case, and
    /// one the classifier does not know.
    static let statuses: [OSStatus] = [
        errSecMissingEntitlement,
        errSecInteractionNotAllowed,
        errSecDuplicateItem,
        errSecItemNotFound,
        errSecAuthFailed,
        errSecParam,
        -1
    ]

    /// The underlying errors the payloads carry: none, a plain error, and each engine / public pair.
    static func underlyingPairs() -> [Pair<Error?, Error?>] {
        [
            Pair("nil", nil, nil),
            Pair("sentinel", SentinelError(tag: "u"), SentinelError(tag: "u")),
            Pair(
                "engine-auth",
                EngineAuthError.service("inner", "inner suggestion", EngineServiceErrorCode.network),
                AuthError.service("inner", "inner suggestion", AWSCognitoAuthError.network)
            ),
            Pair(
                "engine-store",
                EngineCredentialStoreError.securityError(errSecInteractionNotAllowed),
                KeychainStoreError.securityError(errSecInteractionNotAllowed)
            )
        ]
    }

    /// Every case as an engine / public pair, for each underlying error and each status.
    static func everyCase() -> [Pair<EngineCredentialStoreError, KeychainStoreError>] {
        var pairs: [Pair<EngineCredentialStoreError, KeychainStoreError>] = [
            Pair("configuration", .configuration(message: "m-configuration"), .configuration(message: "m-configuration")),
            Pair("itemNotFound", .itemNotFound, .itemNotFound)
        ]
        for underlying in underlyingPairs() {
            let (label, engine, plugin) = (underlying.label, underlying.engine, underlying.plugin)
            pairs += [
                Pair("unknown-\(label)", .unknown("d-unknown", engine), .unknown("d-unknown", plugin)),
                Pair("conversionError-\(label)", .conversionError("d-conversion", engine), .conversionError("d-conversion", plugin)),
                Pair("codingError-\(label)", .codingError("d-coding", engine), .codingError("d-coding", plugin))
            ]
        }
        pairs += statuses.map { Pair("securityError-\($0)", .securityError($0), .securityError($0)) }
        return pairs
    }

    // MARK: Text

    /// Test that the engine's copy reads exactly as `KeychainStoreError` does
    ///
    /// - Given: Every case, with every underlying-error shape and every status that changes the text
    /// - When:
    ///    - `errorDescription`, `recoverySuggestion` and `debugDescription` are read from both types, and
    ///      each is interpolated
    /// - Then:
    ///    - Each is identical, including the source location embedded in the recovery text, and the
    ///      `debugDescription` starts with the literal `KeychainStoreError:`
    ///
    func testTextMatchesKeychainStoreError() {
        for pair in Self.everyCase() {
            let (label, engine, plugin) = (pair.label, pair.engine, pair.plugin)
            XCTAssertEqual(engine.errorDescription, plugin.errorDescription, label)
            XCTAssertEqual(engine.recoverySuggestion, plugin.recoverySuggestion, label)
            XCTAssertEqual(engine.debugDescription, plugin.debugDescription, label)
            XCTAssertEqual("\(engine)", "\(plugin)", label)
            XCTAssertTrue(engine.debugDescription.hasPrefix("KeychainStoreError: "), label)
        }
    }

    /// Test that the source location the recovery text embeds is `KeychainStoreError`'s own
    ///
    /// - Given: The cases whose recovery text reports a bug
    /// - When:
    ///    - The recovery text is read
    /// - Then:
    ///    - It names `AWSPluginsCore/KeychainStoreError.swift`, `recoverySuggestion` and the line of the call
    ///      there (78 for a status on macOS, 91 for the other cases)
    ///
    func testRecoveryTextNamesKeychainStoreErrorsLocation() {
        let status = EngineCredentialStoreError.securityError(errSecInteractionNotAllowed).recoverySuggestion
        let other = EngineCredentialStoreError.unknown("d").recoverySuggestion
#if os(macOS)
        XCTAssertTrue(status.hasSuffix("file: AWSPluginsCore/KeychainStoreError.swift\nfunction: recoverySuggestion\nline: 78"))
#else
        XCTAssertTrue(status.hasSuffix("file: AWSPluginsCore/KeychainStoreError.swift\nfunction: recoverySuggestion\nline: 88"))
#endif
        XCTAssertTrue(other.hasSuffix("file: AWSPluginsCore/KeychainStoreError.swift\nfunction: recoverySuggestion\nline: 91"))
    }

    // MARK: Equality

    /// Test that `EngineCredentialStoreError.==` is `KeychainStoreError.==`
    ///
    /// - Given: Every ordered pair of cases, each built twice with different payloads
    /// - When:
    ///    - The pair is compared as engine errors and as public errors
    /// - Then:
    ///    - The results are identical: the same case is equal whatever the payload, different cases are not
    ///
    func testEqualityMatchesKeychainStoreError() {
        let values: [(EngineCredentialStoreError, KeychainStoreError)] = [
            (.configuration(message: "a"), .configuration(message: "a")),
            (.configuration(message: "b"), .configuration(message: "b")),
            (.unknown("a"), .unknown("a")),
            (.unknown("b", SentinelError(tag: "b")), .unknown("b", SentinelError(tag: "b"))),
            (.conversionError("a"), .conversionError("a")),
            (.conversionError("b", SentinelError(tag: "b")), .conversionError("b", SentinelError(tag: "b"))),
            (.codingError("a"), .codingError("a")),
            (.codingError("b", SentinelError(tag: "b")), .codingError("b", SentinelError(tag: "b"))),
            (.itemNotFound, .itemNotFound),
            (.itemNotFound, .itemNotFound),
            (.securityError(errSecDuplicateItem), .securityError(errSecDuplicateItem)),
            (.securityError(errSecInteractionNotAllowed), .securityError(errSecInteractionNotAllowed))
        ]
        var equalPairs = 0
        for (lhs, lhsPlugin) in values {
            for (rhs, rhsPlugin) in values {
                XCTAssertEqual(lhs == rhs, lhsPlugin == rhsPlugin, "\(lhs) == \(rhs)")
                if lhs == rhs {
                    equalPairs += 1
                }
            }
        }
        XCTAssertEqual(equalPairs, 6 * 4)
    }

    // MARK: Conversions

    /// Test that the engine's copy converts to the same `AuthError` as `KeychainStoreError`
    ///
    /// - Given: Every case as an engine and a public error
    /// - When:
    ///    - Each is converted with `AuthError(converting:)`, as the plugin's glue does
    /// - Then:
    ///    - Both give the same case, strings and `debugDescription`, and the underlying error is the public
    ///      type
    ///
    func testConvertsToTheSameAuthError() throws {
        for pair in Self.everyCase() {
            let (label, engine, plugin) = (pair.label, pair.engine, pair.plugin)
            let fromEngine = try XCTUnwrap(AuthError(converting: engine), label)
            let fromPlugin = try XCTUnwrap(AuthError(converting: plugin), label)
            XCTAssertEqual(fromEngine.errorDescription, fromPlugin.errorDescription, label)
            XCTAssertEqual(fromEngine.recoverySuggestion, fromPlugin.recoverySuggestion, label)
            XCTAssertEqual(fromEngine.debugDescription, fromPlugin.debugDescription, label)
            XCTAssertEqual(
                String(reflecting: fromEngine.underlyingError.map { type(of: $0) }),
                String(reflecting: fromPlugin.underlyingError.map { type(of: $0) }),
                label
            )
        }
    }

    /// Test that the plugin boundary converts both ways, case for case
    ///
    /// - Given: Every case as an engine and a public error
    /// - When:
    ///    - The engine error is converted with `KeychainStoreError(_:)`, and the public one with
    ///      `EngineCredentialStoreError(_:)`
    /// - Then:
    ///    - Each gives the other's case, payload and text, with the underlying error bridged to the other
    ///      side's type, and a round trip gives back the original
    ///
    func testBridgeRoundTrips() {
        for pair in Self.everyCase() {
            let (label, engine, plugin) = (pair.label, pair.engine, pair.plugin)
            let toPlugin = KeychainStoreError(engine)
            XCTAssertEqual(toPlugin.debugDescription, plugin.debugDescription, label)
            XCTAssertEqual(Self.shape(toPlugin), Self.shape(plugin), label)

            let toEngine = EngineCredentialStoreError(plugin)
            XCTAssertEqual(toEngine.debugDescription, engine.debugDescription, label)
            XCTAssertEqual(Self.shape(toEngine), Self.shape(engine), label)

            XCTAssertEqual(Self.shape(EngineCredentialStoreError(toPlugin)), Self.shape(engine), label)
            XCTAssertEqual(Self.shape(KeychainStoreError(toEngine)), Self.shape(plugin), label)
        }
    }

    /// Test that an engine error with the engine's copy underneath reaches the plugin with the public type
    ///
    /// - Given: An `EngineAuthError` whose underlying error is an `EngineCredentialStoreError`
    /// - When:
    ///    - It is converted with `AuthError(_:)`, then back with `EngineAuthError(_:)`
    /// - Then:
    ///    - The `AuthError`'s underlying error is the equal `KeychainStoreError`, and the way back gives the
    ///      engine type again
    ///
    func testUnderlyingErrorIsBridged() throws {
        let engine = EngineAuthError.service("d", "s", EngineCredentialStoreError.securityError(errSecInteractionNotAllowed))
        let auth = AuthError(engine)
        let underlying = try XCTUnwrap(auth.underlyingError as? KeychainStoreError)
        XCTAssertEqual(underlying, .securityError(errSecInteractionNotAllowed))
        guard case .securityError(let status) = underlying else {
            return XCTFail("Expected securityError, got \(underlying)")
        }
        XCTAssertEqual(status, errSecInteractionNotAllowed)

        let back = EngineAuthError(auth)
        XCTAssertTrue(back.underlyingError is EngineCredentialStoreError)
    }

    /// Test that a keychain failure maps onto the case `KeychainStoreError` reports for it
    ///
    /// - Given: Every `KeychainAccessError` case
    /// - When:
    ///    - It is mapped by `EngineCredentialStoreError(_:)` and by `KeychainStoreError(_:)`, directly and
    ///      through `mapping(_:)`
    /// - Then:
    ///    - Both give the same case and text; any other error passes through `mapping(_:)` unchanged
    ///
    func testKeychainAccessErrorMapping() {
        let failures: [KeychainAccessError] = [
            .itemNotFound,
            .securityError(errSecInteractionNotAllowed),
            .securityError(errSecMissingEntitlement),
            .unknown("d-unknown", SentinelError(tag: "u")),
            .unknown("d-unknown", nil)
        ]
        for failure in failures {
            let engine = EngineCredentialStoreError(failure)
            let plugin = KeychainStoreError(failure)
            XCTAssertEqual(Self.shape(engine), Self.shape(plugin), "\(failure)")
            XCTAssertEqual(engine.debugDescription, plugin.debugDescription, "\(failure)")
            XCTAssertThrowsError(try EngineCredentialStoreError.mapping { throw failure }) { error in
                XCTAssertEqual(Self.shape(error), Self.shape(plugin), "\(failure)")
            }
        }
        XCTAssertThrowsError(try EngineCredentialStoreError.mapping { throw SentinelError(tag: "other") }) { error in
            XCTAssertEqual(error as? SentinelError, SentinelError(tag: "other"))
        }
    }

    /// Test that an engine credential-store error leaves through `rethrowingPublicError` as the public type
    ///
    /// - Given: A body that throws an `EngineCredentialStoreError`, and one that throws another error
    /// - When:
    ///    - Each runs in `EngineCredentialStoreError.rethrowingPublicError`
    /// - Then:
    ///    - The first is rethrown as the equal `KeychainStoreError`, the second unchanged
    ///
    func testRethrowingPublicError() {
        XCTAssertThrowsError(try EngineCredentialStoreError.rethrowingPublicError {
            throw EngineCredentialStoreError.securityError(errSecInteractionNotAllowed)
        }) { error in
            XCTAssertEqual(error as? KeychainStoreError, .securityError(errSecInteractionNotAllowed))
        }
        XCTAssertThrowsError(try EngineCredentialStoreError.rethrowingPublicError {
            throw SentinelError(tag: "other")
        }) { error in
            XCTAssertEqual(error as? SentinelError, SentinelError(tag: "other"))
        }
        XCTAssertEqual(try EngineCredentialStoreError.rethrowingPublicError { 1 }, 1)
    }

    // MARK: Helpers

    /// Case, payload and underlying error, with the engine and public types written the same way.
    static func shape(_ error: Error?) -> String {
        switch error {
        case nil:
            return "nil"
        case let store as EngineCredentialStoreError:
            return "store.\(caseName(store))(\(store.errorDescription), \(shape(store.underlyingError)))"
        case let store as KeychainStoreError:
            return "store.\(caseName(store))(\(store.errorDescription), \(shape(store.underlyingError)))"
        case let engine as EngineAuthError:
            return "auth(\(engine.errorDescription), \(engine.recoverySuggestion), \(shape(engine.underlyingError)))"
        case let auth as AuthError:
            return "auth(\(auth.errorDescription), \(auth.recoverySuggestion), \(shape(auth.underlyingError)))"
        case let code as EngineServiceErrorCode:
            return "code.\(code)"
        case let code as AWSCognitoAuthError:
            return "code.\(code)"
        case let error?:
            return "other.\(String(reflecting: type(of: error))).\(String(describing: error))"
        }
    }

    static func caseName(_ error: Error) -> String {
        Mirror(reflecting: error).children.first?.label ?? String(describing: error)
    }
}
