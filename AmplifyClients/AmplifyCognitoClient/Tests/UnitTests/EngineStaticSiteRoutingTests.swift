//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

@_spi(AmplifyExperimental) import AmplifyFoundation
import AWSCognitoIdentityProvider
import Foundation
@testable import AmplifyFoundation
@testable import InternalAWSCognitoAuth
import XCTest
@_spi(AmplifyExperimental) @testable import AmplifyCognitoClient

/// The engine's log sites with no environment of their own (value parsers, the keychain store, the WebAuthn
/// delegate) log through the client's logger on the client's paths, never through the process-global router.
/// The global router is the Auth plugin's once a plugin exists, so these lines used to take the plugin's
/// categories.
final class EngineStaticSiteRoutingTests: XCTestCase {

    private var harness: LiveEngineHarness!
    private var sink: CategoryCapture!
    private var router: RecordingRouter!
    private var savedRouter: (any EngineLogRouter)?

    override func setUp() {
        super.setUp()
        harness = LiveEngineHarness()
        sink = CategoryCapture()
        AmplifyLogging.addSink(sink)
        savedRouter = EngineLog.router
        router = RecordingRouter()
        EngineLog.install(router)
    }

    override func tearDown() {
        if let savedRouter {
            EngineLog.install(savedRouter)
        }
        AmplifyLogging.removeSink(sink)
        harness = nil
        super.tearDown()
    }

    /// Test that the client's paths never reach the global router
    ///
    /// - Given: a recording router installed as the global router, as the Auth plugin installs its own
    /// - When:
    ///    - the live engine signs in (its credential machine reads the inert legacy keychain), parses a
    ///      `GetUser` MFA setting this build does not know, and is asked to resume a saved sign-in whose factor
    ///      and MFA type spellings it does not know
    ///    - the client decodes a saved session whose preferred first factor this build does not know
    ///    - the platform passkey registrant the client hands the engine is made
    /// - Then:
    ///    - the global router resolved nothing
    ///    - each line arrived under the client's category: `AmplifyCognitoClient.KeychainStore`,
    ///      `AmplifyCognitoClient.MFAType` and `AmplifyCognitoClient.AuthFactorType`
    ///    - the registrant logs under `AmplifyCognitoClient.PlatformWebAuthnCredentials`
    func testClientPathsNeverReachTheGlobalRouter() async throws {
        let engine = try harness.engine()
        let payload = try await harness.signedInPayload(on: engine)
        XCTAssertFalse(sink.lines(in: ["AmplifyCognitoClient.KeychainStore"]).isEmpty, "the legacy keychain's lines")

        harness.cognito.once("GetUser") { (_: GetUserInput) in
            GetUserOutput(preferredMfaSetting: "X", userAttributes: [], userMFASettingList: ["X"], username: "alice")
        }
        _ = try await engine.fetchMFAPreference(payload)
        XCTAssertEqual(sink.categories(containing: "unsupported MFA type with value: X"), ["AmplifyCognitoClient.MFAType"])

        // A saved session whose preferred first factor this build does not know, decoded as the client decodes
        // every payload.
        let signedIn: SignedInData
        switch try LiveSessionEngine.credentials(in: payload) {
        case .userPoolOnly(let data), .userPoolAndIdentityPool(let data, _, _):
            signedIn = data
        default:
            return XCTFail("alice's payload has no user pool tokens")
        }
        let userAuth = SignedInData(
            signedInDate: signedIn.signedInDate,
            signInMethod: .apiBased(.userAuth(preferredFirstFactor: .emailOTP)),
            cognitoUserPoolTokens: signedIn.cognitoUserPoolTokens
        )
        let known = try String(decoding: CredentialSlot.encode(.userPoolOnly(signedInData: userAuth)), as: UTF8.self)
        XCTAssertTrue(known.contains(#""EMAIL_OTP""#))
        let unknown = Data(known.replacingOccurrences(of: #""EMAIL_OTP""#, with: #""TELEKINESIS""#).utf8)
        XCTAssertThrowsError(try CredentialSlot.decode(unknown))
        XCTAssertEqual(sink.categories(containing: "value: TELEKINESIS"), ["AmplifyCognitoClient.AuthFactorType"])

        let factor = try XCTUnwrap(ChallengeRecord.State.fake(
            .confirmSignInWithTOTPCode,
            signInMethod: .init(authFlow: "userAuth", preferredFirstFactor: "TELEPATHY")
        ))
        let factorEngine = try harness.engine()
        let resumedFactor = await factorEngine.resumeSignIn(from: factor, epoch: 0)
        XCTAssertNil(resumedFactor)
        XCTAssertEqual(sink.categories(containing: "value: TELEPATHY"), ["AmplifyCognitoClient.AuthFactorType"])

        guard case .challenge(var challenge) = ChallengeRecord.State.fake(.continueSignInWithMFASelection([.sms])) else {
            return XCTFail("no saved MFA selection")
        }
        challenge.step.mfaTypes = ["TELEPHONE_MFA"]
        let mfaEngine = try harness.engine()
        let resumedMFA = await mfaEngine.resumeSignIn(from: .challenge(challenge), epoch: 0)
        XCTAssertNil(resumedMFA)
        XCTAssertEqual(sink.categories(containing: "value: TELEPHONE_MFA"), ["AmplifyCognitoClient.MFAType"])

        #if os(iOS) || os(macOS) || os(visionOS)
        if #available(iOS 17.4, macOS 13.5, visionOS 1.0, *) {
            // The delegate's logger is inspected, not driven: an `ASAuthorizationController` made in a test
            // process without a host app can hang the simulator's main thread.
            let registrantFactory = try LiveWebAuthnCeremonies.platform.registrant(logger: harness.resources().logger)
            let name = try await MainActor.run {
                let credentials = try XCTUnwrap(registrantFactory(nil) as? PlatformWebAuthnCredentials)
                return (credentials.log as? ClientEngineLogger)?.name
            }
            XCTAssertEqual(name, "AmplifyCognitoClient.PlatformWebAuthnCredentials")
        }
        #endif

        XCTAssertEqual(router.scopes, [], "no client line goes through the global router")
        XCTAssertEqual(sink.lines(in: ["MFAType", "AuthFactorType", "KeychainStore", "PlatformWebAuthnCredentials"]), [])
    }
}

/// A global router that records every scope resolved through it, and logs nothing.
private final class RecordingRouter: EngineLogRouter, @unchecked Sendable {

    // `@unchecked Sendable`: `resolved` is only touched while holding `lock`.
    private let lock = NSLock()
    private var resolved: [EngineLogScope] = []

    var scopes: [EngineLogScope] {
        lock.withLock { resolved }
    }

    func logger(_ scope: EngineLogScope) -> EngineLogger {
        lock.withLock { resolved.append(scope) }
        return DiscardingEngineLogger()
    }
}
