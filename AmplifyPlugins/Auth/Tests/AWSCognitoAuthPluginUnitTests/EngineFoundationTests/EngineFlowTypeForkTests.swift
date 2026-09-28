//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import AmplifyFoundation
@testable import AWSCognitoAuthPlugin
import AWSCognitoIdentityProvider
import Foundation
@testable import InternalAWSCognitoAuth
import XCTest

/// Tests for the engine's flow-type forks: `EngineAuthFactorType`, `EngineAuthFlowType` and
/// `EngineAuthProvider`, against the public types they mirror, and for the plugin's converters in
/// `Support/EngineBridge/`. The stored format is gated separately, by `StoredFormatGoldenTests` and its
/// cross-decoders (`StoredFormatForkCrossDecoders+S5b.swift`).
@available(*, deprecated, message: "Exercises the deprecated AuthFlowType.custom, on purpose")
class EngineFlowTypeForkTests: XCTestCase {

    private var previousRouter: (any EngineLogRouter)?

    override func setUp() {
        super.setUp()
        previousRouter = EngineLog.router
    }

    override func tearDown() {
        if let previousRouter {
            EngineLog.install(previousRouter)
        }
        super.tearDown()
    }

    // MARK: Every value of each public type

    static var factors: [AuthFactorType] {
        var factors: [AuthFactorType] = [.password, .passwordSRP, .smsOTP, .emailOTP]
        #if os(iOS) || os(macOS) || os(visionOS)
        if #available(iOS 17.4, macOS 13.5, visionOS 1.0, *) {
            factors.append(.webAuthn)
        }
        #endif
        return factors
    }

    static var flows: [AuthFlowType] {
        [.userSRP, .custom, .customWithSRP, .customWithoutSRP, .userPassword, .userAuth(preferredFirstFactor: nil)]
            + factors.map { .userAuth(preferredFirstFactor: $0) }
    }

    static let providers: [AuthProvider] = [
        .amazon, .apple, .facebook, .google, .twitter,
        .oidc("oidc-name"), .saml("saml-name"), .custom("custom.name"),
        .oidc(""), .custom("www.amazon.com")
    ]

    /// Strings the factor and flow parsers are compared on: every known value, Amplify's own raw values,
    /// the pre-passwordless names, and unknown input.
    static let rawCorpus = [
        "PASSWORD", "PASSWORD_SRP", "SMS_OTP", "EMAIL_OTP", "WEB_AUTHN",
        "password", "passwordSRP", "smsOTP", "emailOTP", "webAuthn",
        "USER_SRP_AUTH", "CUSTOM_AUTH", "CUSTOM_AUTH_WITH_SRP", "CUSTOM_AUTH_WITHOUT_SRP",
        "USER_PASSWORD_AUTH", "USER_AUTH", "user_auth",
        "userSRP", "userPassword", "custom", "customWithSRP", "customWithoutSRP", "userAuth",
        "", "X", " PASSWORD"
    ]

    /// What the plugin extension's `AuthFactorType.init?(rawValue:)` returns, converted to the fork. That
    /// initializer cannot be named from a test module (it is ambiguous with Amplify's synthesized one), and
    /// it is a switch over each factor's `challengeResponse`, so this is the same table.
    private func publicFactor(rawValue: String) -> EngineAuthFactorType? {
        Self.factors.first { $0.challengeResponse == rawValue }.map { EngineAuthFactorType($0) }
    }

    // MARK: Converters

    /// Test that every public factor converts to the fork and back unchanged
    ///
    /// - Given: Every `AuthFactorType` this platform can build
    /// - When:
    ///    - It is converted to `EngineAuthFactorType` and back
    /// - Then:
    ///    - The round trip is the identity, the case name is kept, and the two agree on `rawValue` and
    ///      `challengeResponse`
    ///
    func testFactorRoundTrip() {
        for factor in Self.factors {
            let engine = EngineAuthFactorType(factor)
            XCTAssertEqual(AuthFactorType(engine), factor)
            XCTAssertEqual(FieldDump.fields(of: engine), FieldDump.fields(of: factor))
            // The plugin extension defines `rawValue` as `challengeResponse`; from a test module the name is
            // ambiguous with Amplify's own raw value, so compare through `challengeResponse`.
            XCTAssertEqual(engine.rawValue, factor.challengeResponse)
            XCTAssertEqual(engine.challengeResponse, factor.challengeResponse)
            XCTAssertEqual(EngineAuthFactorType(AuthFactorType(engine)), engine)
        }
    }

    /// Test that every public flow converts to the fork and back unchanged
    ///
    /// - Given: Every `AuthFlowType`, `.custom` and each `userAuth` factor included
    /// - When:
    ///    - It is converted to `EngineAuthFlowType` and back
    /// - Then:
    ///    - The round trip is the identity (so `.custom` stays `.custom`), the case and payload are kept,
    ///      and `rawValue` and the Cognito client flow type agree
    ///
    func testFlowRoundTrip() {
        for flow in Self.flows {
            let engine = EngineAuthFlowType(flow)
            XCTAssertEqual(AuthFlowType(engine), flow, "\(flow)")
            XCTAssertEqual(FieldDump.fields(of: engine), FieldDump.fields(of: flow), "\(flow)")
            XCTAssertEqual(engine.rawValue, flow.rawValue, "\(flow)")
            XCTAssertEqual(engine.getClientFlowType(), flow.getClientFlowType(), "\(flow)")
            XCTAssertEqual(EngineAuthFlowType(AuthFlowType(engine)), engine, "\(flow)")
        }
        XCTAssertNotEqual(EngineAuthFlowType(AuthFlowType.custom), .customWithSRP)
        XCTAssertEqual(EngineAuthFlowType.userAuth, EngineAuthFlowType(AuthFlowType.userAuth))
    }

    /// Test that every public provider converts to the fork and back unchanged
    ///
    /// - Given: Every `AuthProvider` case, with payloads
    /// - When:
    ///    - It is converted to `EngineAuthProvider` and back
    /// - Then:
    ///    - The round trip is the identity, and the case and payload are kept
    ///
    func testProviderRoundTrip() {
        for provider in Self.providers {
            let engine = EngineAuthProvider(provider)
            XCTAssertEqual(AuthProvider(engine), provider)
            XCTAssertEqual(FieldDump.fields(of: engine), FieldDump.fields(of: provider))
            XCTAssertEqual(EngineAuthProvider(AuthProvider(engine)), engine)
        }
    }

    // MARK: Equality tables

    /// Test that the forks' `==` gives the same answer as the public types' for every pair
    ///
    /// - Given: Every pair of values of each public type
    /// - When:
    ///    - Each pair is compared, and so is the converted pair
    /// - Then:
    ///    - The answers are equal. `.custom` and `.customWithSRP` stay unequal in both
    ///
    func testEqualityTablesMatch() {
        for lhs in Self.factors {
            for rhs in Self.factors {
                XCTAssertEqual(EngineAuthFactorType(lhs) == EngineAuthFactorType(rhs), lhs == rhs, "\(lhs) \(rhs)")
            }
        }
        for lhs in Self.flows {
            for rhs in Self.flows {
                XCTAssertEqual(EngineAuthFlowType(lhs) == EngineAuthFlowType(rhs), lhs == rhs, "\(lhs) \(rhs)")
            }
        }
        for lhs in Self.providers {
            for rhs in Self.providers {
                XCTAssertEqual(EngineAuthProvider(lhs) == EngineAuthProvider(rhs), lhs == rhs, "\(lhs) \(rhs)")
            }
        }
        XCTAssertNotEqual(EngineAuthFlowType.custom, .customWithSRP)
    }

    // MARK: Parsers

    /// Test that the fork's factor and flow parsers accept and reject exactly what the public ones do
    ///
    /// - Given: A corpus of known, legacy and unknown strings
    /// - When:
    ///    - Each is parsed with `init?(rawValue:)` (factor, flow) and `legacyInit(rawValue:)` (flow), by
    ///      both the public type and the fork
    /// - Then:
    ///    - The results are the same value, or both `nil`
    ///
    func testParsersMatch() {
        for raw in Self.rawCorpus {
            XCTAssertEqual(EngineAuthFactorType(rawValue: raw), publicFactor(rawValue: raw), raw)
            XCTAssertEqual(EngineAuthFlowType(rawValue: raw), AuthFlowType(rawValue: raw).map { EngineAuthFlowType($0) }, raw)
            XCTAssertEqual(
                EngineAuthFlowType.legacyInit(rawValue: raw),
                AuthFlowType.legacyInit(rawValue: raw).map { EngineAuthFlowType($0) },
                raw
            )
        }
    }

    /// Test that a Cognito challenge name maps to the factor the public type's mapping gave
    ///
    /// - Given: Every Cognito challenge name, plus an unknown one
    /// - When:
    ///    - `authFactor` is read, and `RespondToAuthChallenge` converts the set for `AuthSignInStep`
    /// - Then:
    ///    - Only the five factor challenges map, each to its own factor
    ///
    func testChallengeNameAuthFactor() {
        var expected: [CognitoIdentityProviderClientTypes.ChallengeNameType: EngineAuthFactorType] = [
            .password: .password, .passwordSrp: .passwordSRP, .smsOtp: .smsOTP, .emailOtp: .emailOTP
        ]
        #if os(iOS) || os(macOS) || os(visionOS)
        if #available(iOS 17.4, macOS 13.5, visionOS 1.0, *) {
            expected[.webAuthn] = .webAuthn
        }
        #endif
        let all = CognitoIdentityProviderClientTypes.ChallengeNameType.allCases + [.sdkUnknown("X")]
        for challenge in all {
            XCTAssertEqual(challenge.authFactor, expected[challenge], "\(challenge)")
        }

        let respond = RespondToAuthChallenge(
            challenge: .selectChallenge,
            availableChallenges: all,
            username: "user",
            session: nil,
            parameters: nil
        )
        XCTAssertEqual(respond.getAllowedAuthFactorsForSelection, Set(expected.values))
    }

    /// Test that the provider-name mappings, now on the fork, are the ones the public type had
    ///
    /// - Given: Every provider
    /// - When:
    ///    - Its user-pool and identity-pool provider names are read, and the identity-pool name is parsed back
    /// - Then:
    ///    - The names are the recorded ones, and parsing gives the provider (a custom name parses as `.oidc`)
    ///
    func testProviderNames() {
        struct Names {
            let provider: EngineAuthProvider
            let userPool: String
            let identityPool: String
        }
        let table = [
            Names(provider: .amazon, userPool: "LoginWithAmazon", identityPool: "www.amazon.com"),
            Names(provider: .apple, userPool: "SignInWithApple", identityPool: "appleid.apple.com"),
            Names(provider: .facebook, userPool: "Facebook", identityPool: "graph.facebook.com"),
            Names(provider: .google, userPool: "Google", identityPool: "accounts.google.com"),
            Names(provider: .twitter, userPool: "Twitter", identityPool: "api.twitter.com"),
            Names(provider: .oidc("n1"), userPool: "n1", identityPool: "n1"),
            Names(provider: .saml("n2"), userPool: "n2", identityPool: "n2"),
            Names(provider: .custom("n3"), userPool: "n3", identityPool: "n3")
        ]
        for names in table {
            XCTAssertEqual(names.provider.userPoolProviderName, names.userPool)
            XCTAssertEqual(names.provider.identityPoolProviderName, names.identityPool)
        }
        for names in table.prefix(5) {
            XCTAssertEqual(EngineAuthProvider(identityPoolProviderName: names.identityPool), names.provider)
        }
        XCTAssertEqual(EngineAuthProvider(identityPoolProviderName: "n3"), .oidc("n3"))
    }

    // MARK: Rejected stored values (stored-format gate)

    /// Test that the fork rejects every rejected flow-type and provider fixture, for the same reason
    ///
    /// - Given: The committed must-throw fixtures for `AuthFlowType` and for an unknown `AuthProvider`
    /// - When:
    ///    - Each is decoded with the fork (the provider through its `federatedToken.provider` sub-value)
    /// - Then:
    ///    - Decoding throws the `DecodingError` case recorded for the public type
    ///
    func testForksRejectTheRejectedFixtures() throws {
        let fixtures = StoredFormatFixtures.rejected
        let flowFixtures = fixtures.filter { $0.name.hasPrefix("rejected-authFlowType-") }
        XCTAssertEqual(flowFixtures.count, 4)
        for fixture in flowFixtures {
            let data = try StoredFormatGoldenTests.fixtureData(fixture.name)
            XCTAssertEqual(
                decodingErrorCase(EngineAuthFlowType.self, data),
                fixture.expectedFields()["$error"],
                fixture.name
            )
        }

        let providerFixture = try XCTUnwrap(fixtures.first { $0.name == "rejected-session-unknown-provider" })
        let providers = try ForkCrossCheck.subvalues(
            in: StoredFormatGoldenTests.fixtureData(providerFixture.name),
            of: .provider
        )
        XCTAssertEqual(providers.count, 1)
        for provider in providers {
            XCTAssertEqual(decodingErrorCase(EngineAuthProvider.self, provider), decodingErrorCase(AuthProvider.self, provider))
            XCTAssertEqual(decodingErrorCase(EngineAuthProvider.self, provider), providerFixture.expectedFields()["$error"])
        }
    }

    private func decodingErrorCase<T: Decodable>(_ type: T.Type, _ data: Data) -> String? {
        do {
            _ = try JSONDecoder().decode(T.self, from: data)
            return nil
        } catch let error as DecodingError {
            return FieldDump.caseName(of: error)
        } catch {
            return String(describing: Swift.type(of: error))
        }
    }

    // MARK: Logging (log-transcript gate)

    /// Test that the fork's factor parser logs exactly what the public one does, at the same scope
    ///
    /// - Given: A capturing engine log router
    /// - When:
    ///    - An unsupported factor string is parsed, and then every supported one
    /// - Then:
    ///    - One error is logged under category `AuthFactorType` (never the fork's name), with the public
    ///      type's message; supported factors log nothing
    ///
    func testUnsupportedFactorLogsUnderTheAuthFactorTypeCategory() {
        let router = CapturingRouter()
        EngineLog.install(router)

        XCTAssertNil(EngineAuthFactorType(rawValue: "X"))
        XCTAssertEqual(router.entries, [
            .init(
                scope: .category("AuthFactorType"),
                level: .error,
                message: "Tried to initialize an unsupported MFA type with value: X",
                hasError: false
            )
        ])

        for factor in Self.factors {
            XCTAssertNotNil(EngineAuthFactorType(rawValue: factor.challengeResponse))
        }
        XCTAssertEqual(router.entries.count, 1)
    }
}
