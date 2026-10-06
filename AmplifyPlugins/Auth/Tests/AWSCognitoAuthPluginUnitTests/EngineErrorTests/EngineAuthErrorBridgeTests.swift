//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AWSCognitoIdentityProvider
import Foundation
import Security
import XCTest
@testable import Amplify
@_spi(KeychainStore) @testable import AWSPluginsCore
@testable import AWSCognitoAuthPlugin
@testable import InternalAWSCognitoAuth

/// The engine error type and its plugin bridge.
///
/// - Every `EngineAuthError` case, with sentinel payloads and every kind of underlying error, survives
///   `AuthError(_:)` then `EngineAuthError(_:)`, and the other way round.
/// - `EngineServiceErrorCode` ↔ `AWSCognitoAuthError` is a bijection with identical descriptions.
/// - `EngineAuthError`'s strings and `debugDescription` equal those of the `AuthError` it converts to.
/// - `==` is `AuthError`'s: case only, `.unknown` never equal. The state machine suppresses transitions
///   between equal states, so this table is the contract.
final class EngineAuthErrorBridgeTests: XCTestCase {

    struct SentinelError: Error, Equatable {
        let tag: String
    }

    // MARK: Fixtures

    /// Every underlying-error shape the bridge distinguishes.
    static func underlyingVariants() -> [(String, Error?)] {
        var variants: [(String, Error?)] = [
            ("nil", nil),
            ("sentinel", SentinelError(tag: "u")),
            ("sdk", NotAuthorizedException(message: "sdk message")),
            ("keychain", EngineCredentialStoreError.itemNotFound),
            ("keychain-unknown", EngineCredentialStoreError.unknown("keychain u", SentinelError(tag: "k"))),
            ("nested-engine", EngineAuthError.service("nested d", "nested s", EngineServiceErrorCode.network)),
            ("nested-engine-unknown", EngineAuthError.unknown("nested u", SentinelError(tag: "n")))
        ]
        variants += EngineServiceErrorCode.allCases.map { ("code-\($0)", $0 as Error) }
        return variants
    }

    /// One value of every case, for one underlying error.
    static func everyCase(_ underlying: Error?) -> [EngineAuthError] {
        [
            .configuration("d-configuration", "s-configuration", underlying),
            .service("d-service", "s-service", underlying),
            .unknown("d-unknown", underlying),
            .validation("f-validation", "d-validation", "s-validation", underlying),
            .notAuthorized("d-notAuthorized", "s-notAuthorized", underlying),
            .invalidState("d-invalidState", "s-invalidState", underlying),
            .signedOut("d-signedOut", "s-signedOut", underlying),
            .sessionExpired("d-sessionExpired", "s-sessionExpired", underlying)
        ]
    }

    /// Compile-time exhaustiveness for `everyCase`: a new case breaks this switch.
    static func caseName(_ error: EngineAuthError) -> String {
        switch error {
        case .configuration: "configuration"
        case .service: "service"
        case .unknown: "unknown"
        case .validation: "validation"
        case .notAuthorized: "notAuthorized"
        case .invalidState: "invalidState"
        case .signedOut: "signedOut"
        case .sessionExpired: "sessionExpired"
        }
    }

    static func caseName(_ error: AuthError) -> String {
        switch error {
        case .configuration: "configuration"
        case .service: "service"
        case .unknown: "unknown"
        case .validation: "validation"
        case .notAuthorized: "notAuthorized"
        case .invalidState: "invalidState"
        case .signedOut: "signedOut"
        case .sessionExpired: "sessionExpired"
        }
    }

    static func field(_ error: EngineAuthError) -> String? {
        if case .validation(let field, _, _, _) = error { field } else { nil }
    }

    static func field(_ error: AuthError) -> String? {
        if case .validation(let field, _, _, _) = error { field } else { nil }
    }

    /// The underlying error, reduced to something comparable across the two families.
    static func shape(_ error: Error?) -> String {
        switch error {
        case nil:
            return "nil"
        case let code as EngineServiceErrorCode:
            return "code.\(code)"
        case let code as AWSCognitoAuthError:
            return "code.\(code)"
        case let engine as EngineAuthError:
            return "auth.\(caseName(engine))(\(field(engine) ?? "-"), \(rawDescription(engine)), \(engine.recoverySuggestion), \(shape(engine.underlyingError)))"
        case let auth as AuthError:
            return "auth.\(caseName(auth))(\(field(auth) ?? "-"), \(rawDescription(auth)), \(auth.recoverySuggestion), \(shape(auth.underlyingError)))"
        case let store as EngineCredentialStoreError:
            return "keychain.\(storeCaseName(store))(\(store.errorDescription), \(shape(store.underlyingError)))"
        case let store as KeychainStoreError:
            return "keychain.\(storeCaseName(store))(\(store.errorDescription), \(shape(store.underlyingError)))"
        case let error?:
            return "other.\(String(reflecting: type(of: error))).\(String(describing: error))"
        }
    }

    /// The case name of a credential-store error, public or engine: its payload label, or the case itself.
    static func storeCaseName(_ error: Error) -> String {
        Mirror(reflecting: error).children.first?.label ?? String(describing: error)
    }

    /// The description payload, before `.unknown`'s prefix.
    static func rawDescription(_ error: EngineAuthError) -> String {
        switch error {
        case .configuration(let d, _, _), .service(let d, _, _), .unknown(let d, _), .validation(_, let d, _, _),
             .notAuthorized(let d, _, _), .invalidState(let d, _, _), .signedOut(let d, _, _),
             .sessionExpired(let d, _, _):
            d
        }
    }

    static func rawDescription(_ error: AuthError) -> String {
        switch error {
        case .configuration(let d, _, _), .service(let d, _, _), .unknown(let d, _), .validation(_, let d, _, _),
             .notAuthorized(let d, _, _), .invalidState(let d, _, _), .signedOut(let d, _, _),
             .sessionExpired(let d, _, _):
            d
        }
    }

    // MARK: Round trips

    /// Test that every engine error survives the plugin boundary and back
    ///
    /// - Given: Every `EngineAuthError` case, with sentinel strings and every underlying-error shape
    /// - When:
    ///    - It is converted with `AuthError(_:)`, then back with `EngineAuthError(_:)`
    /// - Then:
    ///    - The `AuthError` has the same case, field, strings and underlying error, with engine types bridged
    ///      to their public counterparts
    ///    - The round trip gives back the same case, field, strings and underlying error
    ///
    func testEngineToPluginToEngineRoundTrip() {
        var checked = 0
        for (label, underlying) in Self.underlyingVariants() {
            for engine in Self.everyCase(underlying) {
                let auth = AuthError(engine)
                XCTAssertEqual(Self.caseName(auth), Self.caseName(engine), label)
                XCTAssertEqual(Self.field(auth), Self.field(engine), label)
                XCTAssertEqual(Self.rawDescription(auth), Self.rawDescription(engine), label)
                XCTAssertEqual(auth.recoverySuggestion, engine.recoverySuggestion, label)
                XCTAssertEqual(Self.shape(auth.underlyingError), Self.shape(engine.underlyingError), label)
                XCTAssertFalse(auth.underlyingError is EngineServiceErrorCode, label)
                XCTAssertFalse(auth.underlyingError is EngineAuthError, label)
                XCTAssertFalse(auth.underlyingError is EngineCredentialStoreError, label)

                let back = EngineAuthError(auth)
                XCTAssertEqual(Self.caseName(back), Self.caseName(engine), label)
                XCTAssertEqual(Self.field(back), Self.field(engine), label)
                XCTAssertEqual(Self.rawDescription(back), Self.rawDescription(engine), label)
                XCTAssertEqual(back.recoverySuggestion, engine.recoverySuggestion, label)
                XCTAssertEqual(Self.shape(back.underlyingError), Self.shape(engine.underlyingError), label)
                XCTAssertEqual(
                    String(reflecting: back.underlyingError.map { type(of: $0) }),
                    String(reflecting: engine.underlyingError.map { type(of: $0) }),
                    label
                )
                checked += 1
            }
        }
        XCTAssertEqual(checked, 8 * (7 + EngineServiceErrorCode.allCases.count))
    }

    /// Test that every plugin error survives the engine boundary and back
    ///
    /// - Given: Every `AuthError` case, built by converting the engine fixtures
    /// - When:
    ///    - It is converted with `EngineAuthError(_:)`, then back with `AuthError(_:)`
    /// - Then:
    ///    - The result has the same case, field, strings, underlying type and underlying value
    ///
    func testPluginToEngineToPluginRoundTrip() {
        for (label, underlying) in Self.underlyingVariants() {
            for auth in Self.everyCase(underlying).map({ AuthError($0) }) {
                let engine = EngineAuthError(auth)
                XCTAssertEqual(Self.shape(engine), Self.shape(auth), label)
                let back = AuthError(engine)
                XCTAssertEqual(Self.shape(back), Self.shape(auth), label)
                XCTAssertEqual(back.errorDescription, auth.errorDescription, label)
                XCTAssertEqual(back.debugDescription, auth.debugDescription, label)
                XCTAssertEqual(
                    String(reflecting: back.underlyingError.map { type(of: $0) }),
                    String(reflecting: auth.underlyingError.map { type(of: $0) }),
                    label
                )
            }
        }
        // The temporary safety net `extension AuthError: EngineAuthErrorConvertible` is gone: no plugin error
        // reaches engine code any more, so an `AuthError` must not satisfy an engine match.
        let auth: Any = AuthError.service("d", "s", AWSCognitoAuthError.userNotFound)
        XCTAssertFalse(auth is EngineAuthErrorConvertible)
    }

    /// Test that the service codes are a bijection with the same descriptions
    ///
    /// - Given: Every `EngineServiceErrorCode` and every `AWSCognitoAuthError`
    /// - When:
    ///    - Each is converted to the other and back
    /// - Then:
    ///    - Case names match, the round trip is the identity, and `errorDescription` is identical
    ///
    func testServiceCodeBijection() {
        XCTAssertEqual(EngineServiceErrorCode.allCases.count, 34)
        var publicCodes: Set<String> = []
        for code in EngineServiceErrorCode.allCases {
            let publicCode = AWSCognitoAuthError(code)
            XCTAssertEqual("\(publicCode)", "\(code)")
            XCTAssertEqual(EngineServiceErrorCode(publicCode), code)
            XCTAssertEqual(publicCode.errorDescription, code.errorDescription)
            XCTAssertEqual((publicCode as NSError).code, (code as NSError).code, "\(code)")
            publicCodes.insert("\(publicCode)")
        }
        XCTAssertEqual(publicCodes.count, 34)
        XCTAssertTrue(EngineServiceErrorCode.network.errorDescription?.hasPrefix("AWSCognitoAuthError.network: ") == true)
    }

    // MARK: Strings

    /// Test that engine errors print exactly what the `AuthError` they convert to prints
    ///
    /// - Given: Every case with every underlying-error shape
    /// - When:
    ///    - `errorDescription`, `recoverySuggestion`, `debugDescription` and string interpolation are read on
    ///      the engine error and on `AuthError(_:)` of it
    /// - Then:
    ///    - They are identical, including the literal `AuthError:` prefix and the `Caused by:` recursion
    ///
    func testStringsMatchAuthError() {
        for (label, underlying) in Self.underlyingVariants() {
            for engine in Self.everyCase(underlying) {
                let auth = AuthError(engine)
                XCTAssertEqual(engine.errorDescription, auth.errorDescription, label)
                XCTAssertEqual(engine.recoverySuggestion, auth.recoverySuggestion, label)
                XCTAssertEqual(engine.debugDescription, auth.debugDescription, label)
                XCTAssertEqual("\(engine)", "\(auth)", label)
                XCTAssertEqual(String(describing: engine), String(describing: auth), label)
                XCTAssertTrue(engine.debugDescription.hasPrefix("AuthError: "), label)
            }
        }
    }

    /// Test that an engine error prints an underlying Amplify error the way `AuthError` does
    ///
    /// - Given: An `AuthError` and a `KeychainStoreError`, which are `AmplifyError`s, as the underlying error
    ///   of an engine error and of an `AuthError`
    /// - When:
    ///    - Both `debugDescription`s are read
    /// - Then:
    ///    - They are identical: the engine's interpolation prints an `AmplifyError`'s `debugDescription`
    ///
    func testUnderlyingAmplifyErrorsPrintTheSame() {
        let underlyings: [Error] = [
            AuthError.service("inner", "inner suggestion", AWSCognitoAuthError.codeExpired),
            AuthError.unknown("inner unknown"),
            KeychainStoreError.securityError(errSecInteractionNotAllowed),
            KeychainStoreError.unknown("keychain", SentinelError(tag: "k"))
        ]
        for underlying in underlyings {
            let engine = EngineAuthError.service("outer", "outer suggestion", underlying)
            let auth = AuthError.service("outer", "outer suggestion", underlying)
            XCTAssertEqual(engine.debugDescription, auth.debugDescription)
        }
        // The engine's copy of `KeychainStoreError` prints as the public type does.
        let storeErrors: [(EngineCredentialStoreError, KeychainStoreError)] = [
            (.securityError(errSecInteractionNotAllowed), .securityError(errSecInteractionNotAllowed)),
            (.unknown("keychain", SentinelError(tag: "k")), .unknown("keychain", SentinelError(tag: "k")))
        ]
        for (engineStoreError, storeError) in storeErrors {
            let engine = EngineAuthError.service("outer", "outer suggestion", engineStoreError)
            let auth = AuthError.service("outer", "outer suggestion", storeError)
            XCTAssertEqual(engine.debugDescription, auth.debugDescription)
        }
    }

    /// Test `AuthError(converting:)`
    ///
    /// - Given: An `AuthError`, an SDK exception, an engine error, a plugin error enum and a plain error
    /// - When:
    ///    - Each is converted
    /// - Then:
    ///    - The first four give the `AuthError` of their `authError` / `engineError`, the last gives `nil`
    ///
    func testConverting() throws {
        let auth = AuthError.notAuthorized("d", "s")
        XCTAssertEqual(Self.shape(try XCTUnwrap(AuthError(converting: auth))), Self.shape(auth))

        let sdk = UserNotFoundException(message: "m")
        let fromSDK = try XCTUnwrap(AuthError(converting: sdk))
        XCTAssertEqual(Self.shape(fromSDK), Self.shape(AuthError(sdk.engineError)))
        XCTAssertEqual(fromSDK.underlyingError as? AWSCognitoAuthError, .userNotFound)

        let engine = EngineAuthError.sessionExpired("d", "s", EngineServiceErrorCode.network)
        XCTAssertEqual(Self.shape(try XCTUnwrap(AuthError(converting: engine))), Self.shape(AuthError(engine)))

        let keychain = KeychainStoreError.itemNotFound
        XCTAssertEqual(Self.shape(try XCTUnwrap(AuthError(converting: keychain))), Self.shape(keychain.authError))

        let engineKeychain = EngineCredentialStoreError.itemNotFound
        XCTAssertEqual(Self.shape(try XCTUnwrap(AuthError(converting: engineKeychain))), Self.shape(keychain.authError))

        XCTAssertNil(AuthError(converting: SentinelError(tag: "plain")))
    }

    // MARK: Equality

    /// Test that `EngineAuthError.==` is `AuthError.==`
    ///
    /// - Given: Every ordered pair of cases, each built twice with different payloads
    /// - When:
    ///    - The pair is compared as engine errors and as the `AuthError`s they convert to
    /// - Then:
    ///    - The results are identical: same case and not `.unknown` is equal, anything else is not.
    ///      This includes `.unknown == .unknown` being `false`
    ///    - `NSError` codes, which `WebAuthnError.==` compares, are identical case for case
    ///
    func testEqualityTable() {
        let left = Self.everyCase(nil)
        let right = Self.everyCase(SentinelError(tag: "other")).map { error -> EngineAuthError in
            switch error {
            case .configuration(_, _, let e): .configuration("x", "y", e)
            case .service(_, _, let e): .service("x", "y", e)
            case .unknown(_, let e): .unknown("x", e)
            case .validation(_, _, _, let e): .validation("f2", "x", "y", e)
            case .notAuthorized(_, _, let e): .notAuthorized("x", "y", e)
            case .invalidState(_, _, let e): .invalidState("x", "y", e)
            case .signedOut(_, _, let e): .signedOut("x", "y", e)
            case .sessionExpired(_, _, let e): .sessionExpired("x", "y", e)
            }
        }
        var equalPairs: [String] = []
        for lhs in left + right {
            for rhs in left + right {
                let engineEqual = lhs == rhs
                let authEqual = AuthError(lhs) == AuthError(rhs)
                XCTAssertEqual(engineEqual, authEqual, "\(Self.caseName(lhs)) == \(Self.caseName(rhs))")
                XCTAssertEqual(engineEqual, Self.caseName(lhs) == Self.caseName(rhs) && Self.caseName(lhs) != "unknown")
                if engineEqual {
                    equalPairs.append("\(Self.caseName(lhs))")
                }
            }
        }
        // 7 comparable cases, 2 values each, compared in both orders and with themselves.
        XCTAssertEqual(equalPairs.count, 7 * 4)
        let unknown = EngineAuthError.unknown("same", nil)
        XCTAssertFalse(unknown == unknown)

        for error in left {
            XCTAssertEqual((error as NSError).code, (AuthError(error) as NSError).code, Self.caseName(error))
        }
    }
}
