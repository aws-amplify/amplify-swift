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

/// Tests for the engine fork `EngineMFAType` against `Amplify.MFAType` and the plugin's
/// `MFATypeExtension.swift`, and for the converter in `Support/EngineBridge/MFAType+Engine.swift`.
class EngineMFATypeForkTests: XCTestCase {

    private static let mfaTypes = EnginePayloadForkTests.mfaTypes

    private static var mfaSets: [Set<MFAType>] {
        EnginePayloadForkTests.mfaSets
    }

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

    // MARK: EngineMFAType

    /// Test that every public MFA type converts to the fork and back, with the same strings
    ///
    /// - Given: Every `MFAType` case
    /// - When:
    ///    - Each is converted to `EngineMFAType`, and back
    /// - Then:
    ///    - The round trip is the identity, and `rawValue` / `challengeResponse` are the plugin extension's
    ///
    func testMFATypeRoundTrip() {
        for mfaType in Self.mfaTypes {
            let engine = EngineMFAType(mfaType)
            XCTAssertEqual(MFAType(engine), mfaType)
            // The plugin extension's `rawValue` is `challengeResponse`; it cannot be named here, because it
            // is ambiguous with Amplify's synthesized one.
            XCTAssertEqual(engine.rawValue, mfaType.challengeResponse)
            XCTAssertEqual(engine.challengeResponse, mfaType.challengeResponse)
        }
        XCTAssertEqual(Set(Self.mfaTypes.map { EngineMFAType($0) }).count, 3)
    }

    /// Test that the fork parses the strings the plugin extension parses
    ///
    /// - Given: A corpus of MFA strings: the Cognito names in several cases, Amplify's raw values, unknown
    /// - When:
    ///    - Each is parsed by `EngineMFAType(rawValue:)`
    /// - Then:
    ///    - The result is the public type's, as the plugin extension's case-insensitive comparison of each
    ///      `challengeResponse` gives it. (That initializer cannot be named from a test module: it is
    ///      ambiguous with Amplify's synthesized one.)
    ///
    func testMFATypeParserParity() {
        let corpus = [
            "SMS_MFA", "SOFTWARE_TOKEN_MFA", "EMAIL_OTP", "sms_mfa", "Software_Token_Mfa", "email_otp",
            "sms", "totp", "email", "SMS", "", "X", " SMS_MFA"
        ]
        for raw in corpus {
            let expected = Self.mfaTypes.first {
                raw.caseInsensitiveCompare($0.challengeResponse) == .orderedSame
            }
            XCTAssertEqual(EngineMFAType(rawValue: raw, logger: DiscardingEngineLogger()).map { MFAType($0) }, expected, raw)
        }
    }

    /// Test that an unsupported MFA string logs under the public type's category
    ///
    /// - Given: A capturing caller's logger, and a global router that must see nothing
    /// - When:
    ///    - An unsupported MFA string is parsed with the caller's logger, and then every supported one
    /// - Then:
    ///    - One error is logged through the caller's logger under category `MFAType` (never the fork's
    ///      name), with the public extension's message; supported values log nothing; the global router
    ///      sees nothing
    ///
    func testUnsupportedMFATypeLogsUnderTheMFATypeCategory() {
        let router = CapturingRouter()
        let global = CapturingRouter()
        EngineLog.install(global)
        let logger = router.scopedLogger()

        XCTAssertNil(EngineMFAType(rawValue: "X", logger: logger))
        for mfaType in Self.mfaTypes {
            XCTAssertNotNil(EngineMFAType(rawValue: mfaType.challengeResponse, logger: logger))
        }
        XCTAssertEqual(global.entries, [])
        XCTAssertEqual(router.entries, [
            .init(
                scope: .category("MFAType"),
                level: .error,
                message: "Tried to initialize an unsupported MFA type with value: X",
                hasError: false
            )
        ])
    }

    /// Test that the legacy set description is what interpolating a `Set<MFAType>` printed
    ///
    /// - Given: Every set of MFA types
    /// - When:
    ///    - The fork's `legacyDescription(of:)` and `"\(Set<MFAType>)"` describe it
    /// - Then:
    ///    - For zero or one element the texts are equal; for more, they hold the same elements (a set's
    ///      iteration order was never stable)
    ///
    func testLegacyMFASetDescriptionMatchesThePublicSet() {
        for set in Self.mfaSets {
            let legacy = EngineMFAType.legacyDescription(of: Set(set.map { EngineMFAType($0) }))
            let expected = "\(set)"
            if set.count < 2 {
                XCTAssertEqual(legacy, expected)
            } else {
                XCTAssertEqual(elements(of: legacy), elements(of: expected), expected)
            }
        }
    }

    private func elements(of description: String) -> Set<String> {
        Set(description.dropFirst().dropLast().components(separatedBy: ", "))
    }

    /// Test that the MFA-setup error still names the public MFA type
    ///
    /// - Given: An `MFA_SETUP` challenge whose `MFAS_CAN_SETUP` lists only `SMS_MFA`
    /// - When:
    ///    - `UserPoolSignInHelper.parseResponse` handles it
    /// - Then:
    ///    - The error event's message is the one that interpolated a `Set<Amplify.MFAType>` before the fork
    ///
    func testMFASetupErrorMessageNamesThePublicType() {
        let response = RespondToAuthChallengeOutput(
            challengeName: .mfaSetup,
            challengeParameters: ["MFAS_CAN_SETUP": "[\"SMS_MFA\"]"],
            session: "session"
        )

        let event = UserPoolSignInHelper.parseResponse(response, for: "user", signInMethod: .apiBased(.userSRP), logger: AmplifyEngineLogRouter())

        guard let signInEvent = event as? SignInEvent,
              case .throwAuthError(.invalidServiceResponse(let message)) = signInEvent.eventType else {
            return XCTFail("Expected an invalid-service-response error, got \(event)")
        }
        let publicSet: Set<MFAType> = [.sms]
        XCTAssertEqual(message, "Cannot initiate MFA setup from available Types: \(publicSet)")
        XCTAssertEqual(message, "Cannot initiate MFA setup from available Types: [Amplify.MFAType.sms]")
    }
}
