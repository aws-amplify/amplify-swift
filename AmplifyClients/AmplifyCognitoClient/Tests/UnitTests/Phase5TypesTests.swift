//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

#if os(iOS) || os(macOS) || os(visionOS)
import AuthenticationServices
#endif
@_spi(AmplifyExperimental) import AmplifyFoundation
import InternalAWSCognitoAuth
import XCTest
@_spi(AmplifyExperimental) @testable import AmplifyCognitoClient

/// The public types of the operations beyond sign-in and the session operations: the two new error cases,
/// and those operations' options and results.
final class Phase5TypesTests: XCTestCase {

    // MARK: Errors

    /// - Given: one error of each new case
    /// - When: its `AmplifyError` members and its kind are read
    /// - Then:
    ///    - it carries its description, suggestion and underlying error, and the ceremony failure; two
    ///      ceremony failures of different kinds are not equivalent
    func testNewErrorCasesCarryTheirPayload() {
        let underlying = FixtureError(description: "platform")
        let cancelled = AuthClientError.userCancelled("closed", "retry", underlying)
        let exists = AuthClientError.webAuthnCeremonyFailed(.credentialAlreadyExists, "exists", "use it", underlying)

        for (error, description, suggestion) in [(cancelled, "closed", "retry"), (exists, "exists", "use it")] {
            XCTAssertEqual(error.errorDescription, description)
            XCTAssertEqual(error.recoverySuggestion, suggestion)
            XCTAssertTrue(error.underlyingError is FixtureError)
        }
        XCTAssertEqual(cancelled.kind, .userCancelled)
        XCTAssertEqual(exists.kind, .webAuthnCeremonyFailed(.credentialAlreadyExists))
        XCTAssertFalse(exists.isEquivalent(to: .webAuthnCeremonyFailed(.failed, "exists", "use it")))
        XCTAssertFalse(cancelled.isEquivalent(to: .unknown("closed", "retry")))
    }

    /// - Given: each new error case
    /// - When: a credential provider maps it onto the provider contract
    /// - Then:
    ///    - it is `unknown`: neither means signed out
    func testNewErrorCasesMapToUnknownForProviders() {
        for error in [AuthClientError.userCancelled("d", "s"), .webAuthnCeremonyFailed(.failed, "d", "s")] {
            guard case .unknown = CredentialsError(authClientError: error) else {
                return XCTFail("\(error)")
            }
        }
    }

    // MARK: Options and results

    /// - Given: every such option type built with no arguments
    /// - When: its fields are read
    /// - Then:
    ///    - the defaults are the plugin's: no attributes, validation data or metadata, no alias forcing,
    ///      no device name, no developer identity
    func testOptionDefaultsMatchThePlugin() {
        XCTAssertEqual(AuthClientSignUpOptions(), AuthClientSignUpOptions(userAttributes: [], validationData: [:], clientMetadata: [:]))
        XCTAssertNil(AuthClientConfirmSignUpOptions().forceAliasCreation)
        XCTAssertEqual(AuthClientConfirmSignUpOptions().clientMetadata, [:])
        XCTAssertEqual(AuthClientResendSignUpCodeOptions().clientMetadata, [:])
        XCTAssertEqual(AuthClientResetPasswordOptions().clientMetadata, [:])
        XCTAssertEqual(AuthClientConfirmResetPasswordOptions().clientMetadata, [:])
        XCTAssertEqual(AuthClientUpdateUserAttributesOptions().clientMetadata, [:])
        XCTAssertEqual(AuthClientSendVerificationCodeOptions().clientMetadata, [:])
        XCTAssertNil(AuthClientVerifyTOTPSetupOptions().friendlyDeviceName)
        XCTAssertNil(AuthClientFederateToIdentityPoolOptions().developerProvidedIdentityId)
    }

    /// Mirrors `AuthSignUpResult.isSignUpComplete`.
    ///
    /// - Given: a sign-up result for each step
    /// - When: `isSignUpComplete` is read
    /// - Then:
    ///    - it is false only for `.confirmUser`
    func testSignUpIsCompleteUnlessTheUserMustConfirm() {
        XCTAssertFalse(AuthClientSignUpResult(.confirmUser()).isSignUpComplete)
        XCTAssertTrue(AuthClientSignUpResult(.completeAutoSignIn("session")).isSignUpComplete)
        XCTAssertTrue(AuthClientSignUpResult(.done).isSignUpComplete)
    }

    /// A ceremony context compares by its window only: its runner is a closure.
    ///
    /// - Given: two contexts with no window and different runners
    /// - When: they, and requests carrying them, are compared
    /// - Then:
    ///    - they are equal, and a request without a context differs from none
    func testCeremonyContextComparesByWindow() {
        let first = EngineCeremonyContext(anchor: nil) { body in try await body() }
        let second = EngineCeremonyContext(anchor: nil) { _ in Data() }
        XCTAssertEqual(first, second)

        let plain = EngineSignInRequest(username: "u", password: nil, authFlowType: nil, clientMetadata: [:])
        var anchored = plain
        anchored.webAuthn = first
        XCTAssertNil(plain.webAuthn)
        XCTAssertNotEqual(plain, anchored)
    }

    #if os(iOS) || os(macOS) || os(visionOS)
    /// The seam carries the engine's anchor box, the one `WebAuthnCredentialOperations.associate` takes, and
    /// the engine's runner type: the client has no copy of either.
    ///
    /// - Given: a window boxed on the main actor, in the engine's `EnginePresentationAnchorBox`
    /// - When: ceremony contexts are built from that box and from another box of the same window
    /// - Then:
    ///    - the context holds that very box, which unboxes to the window
    ///    - contexts with the same box are equal, whatever their runners, and a second box of the same
    ///      window is a different anchor
    @MainActor
    func testCeremonyContextCarriesTheEnginesAnchorBox() {
        let window = ASPresentationAnchor()
        let box = EnginePresentationAnchorBox(window)
        let context = EngineCeremonyContext(anchor: box, ceremony: WebAuthnCredentialOperations.runCeremonyDirectly)

        XCTAssertTrue(context.anchor === box)
        XCTAssertTrue(context.anchor?.anchor === window)
        XCTAssertEqual(context, EngineCeremonyContext(anchor: box) { _ in Data() })
        XCTAssertNotEqual(
            context,
            EngineCeremonyContext(anchor: EnginePresentationAnchorBox(window), ceremony: WebAuthnCredentialOperations.runCeremonyDirectly)
        )
    }
    #endif
}
