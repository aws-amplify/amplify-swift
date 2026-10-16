//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

#if os(iOS) || os(macOS) || os(visionOS)
import Foundation
import InternalAWSCognitoAuth
import XCTest
@_spi(AmplifyExperimental) @testable import AmplifyCognitoClient

/// Pins `WebUIOptions` to the plugin's hosted-UI options.
///
/// This target cannot import Amplify, so the plugin's values are transcribed, citing the file they
/// came from:
///
/// - `AmplifyPlugins/Auth/Sources/AWSCognitoAuthPlugin/Models/Options/AWSAuthWebUISignInOptions.swift`
///   (fields, `Prompt`)
///
/// The engine builds the authorize request from the options the client hands it
/// (`HostedUIOptions(_:anchor:configuredScopes:)`), with its own `HostedUIRequestHelper.createSignInURL` and
/// `userPoolProviderName`, the plugin's; `LiveEngineWebUITests` pins the resulting query items end to end.
final class WebUIOptionsTests: XCTestCase {

    /// The engine's hosted-UI options for `options`, as the live engine builds them: the core's request, with the
    /// options' own nonce (the core mints one when they have none).
    private static func engineOptions(_ options: WebUIOptions, configuredScopes: [String]) -> HostedUIOptions {
        HostedUIOptions(
            EngineWebUIOptions(options, nonce: options.nonce ?? "minted-nonce"),
            anchor: nil,
            configuredScopes: configuredScopes
        )
    }

    // MARK: - Defaults

    /// The design's two new defaults, and nothing else set.
    ///
    /// - Given: `WebUIOptions()`
    /// - When:
    ///    - its fields are read
    /// - Then:
    ///    - `whenBrowserBusy` is `.fail` and `prefersEphemeralSession` is `true`
    ///    - every parity field is `nil`, so the configuration's scopes and Cognito's defaults apply
    func testDefaultsAreFailAndEphemeralWithNoParityFieldsSet() {
        let options = WebUIOptions()

        XCTAssertEqual(options.whenBrowserBusy, .fail)
        XCTAssertTrue(options.prefersEphemeralSession)
        XCTAssertNil(options.scopes)
        XCTAssertNil(options.provider)
        XCTAssertNil(options.idpIdentifier)
        XCTAssertNil(options.nonce)
        XCTAssertNil(options.language)
        XCTAssertNil(options.loginHint)
        XCTAssertNil(options.prompt)
        XCTAssertNil(options.resource)
    }

    /// Defaults ask the engine for the configured scopes and nothing else.
    ///
    /// - Given: `WebUIOptions()`
    /// - When:
    ///    - the engine's hosted-UI options are built from it against configured scopes `["openid", "email"]`
    /// - Then:
    ///    - the scopes are the configured ones, and no provider, language, login hint, prompt or resource is set
    func testDefaultsAskForTheConfiguredScopesOnly() {
        let options = Self.engineOptions(WebUIOptions(), configuredScopes: ["openid", "email"])

        XCTAssertEqual(options.scopes, ["openid", "email"])
        XCTAssertEqual(options.providerInfo, HostedUIProviderInfo(authProvider: nil, idpIdentifier: nil))
        XCTAssertNil(options.language)
        XCTAssertNil(options.loginHint)
        XCTAssertNil(options.prompt)
        XCTAssertNil(options.resource)
    }

    // MARK: - The engine's options

    /// Every parity field reaches the engine's hosted-UI options, which the engine's `createSignInURL` turns into
    /// the authorize request's items (names and values pinned end to end by `LiveEngineWebUITests`).
    ///
    /// - Given: options with every field set, and `idpIdentifier` absent so `provider` applies
    /// - When:
    ///    - the engine's hosted-UI options are built from them
    /// - Then:
    ///    - each field is carried: the request's scopes, the engine's provider of the same case, the nonce, the
    ///      language, the login hint, the prompt space-separated in order, the resource, and the privacy
    func testEveryFieldReachesTheEnginesOptions() {
        let options = WebUIOptions(
            prefersEphemeralSession: false,
            scopes: ["profile", "openid"],
            provider: .google,
            nonce: "n-123",
            language: "fr",
            loginHint: "alice@example.com",
            prompt: [.login, .selectAccount],
            resource: "myapp://resource"
        )

        let engine = Self.engineOptions(options, configuredScopes: ["ignored"])

        XCTAssertEqual(engine.scopes, ["profile", "openid"])
        XCTAssertEqual(engine.providerInfo, HostedUIProviderInfo(authProvider: .google, idpIdentifier: nil))
        XCTAssertEqual(engine.nonce, "n-123")
        XCTAssertEqual(engine.language, "fr")
        XCTAssertEqual(engine.loginHint, "alice@example.com")
        XCTAssertEqual(engine.prompt, "login select_account")
        XCTAssertEqual(engine.resource, "myapp://resource")
        XCTAssertFalse(engine.preferPrivateSession)
    }

    /// Both `idpIdentifier` and `provider` reach the engine, whose authorize URL sends `idp_identifier` alone, as the
    /// plugin's does (`LiveEngineWebUITests.testTheAuthorizeRequestCarriesTheOptions`).
    ///
    /// - Given: options with both `idpIdentifier` and `provider`
    /// - When:
    ///    - the engine's hosted-UI options are built from them
    /// - Then:
    ///    - the provider info holds both
    func testIdpIdentifierAndProviderBothReachTheEngine() {
        let options = WebUIOptions(provider: .saml("Okta"), idpIdentifier: "corp.example.com")

        let engine = Self.engineOptions(options, configuredScopes: ["openid"])

        XCTAssertEqual(engine.providerInfo, HostedUIProviderInfo(authProvider: .saml("Okta"), idpIdentifier: "corp.example.com"))
    }

    /// Explicit scopes replace the configured ones rather than adding to them, including an empty list.
    ///
    /// - Given: options with `scopes: []`
    /// - When:
    ///    - the engine's hosted-UI options are built against non-empty configured scopes
    /// - Then:
    ///    - the scopes are empty, as `request.options.scopes ?? configured` produces in the plugin
    func testExplicitScopesReplaceTheConfiguredScopes() {
        XCTAssertEqual(Self.engineOptions(WebUIOptions(scopes: []), configuredScopes: ["openid"]).scopes, [])
    }

    /// An empty prompt list sends nothing, the one documented divergence from the plugin.
    ///
    /// - Given: options with `prompt: []`
    /// - When:
    ///    - the engine's hosted-UI options are built from them
    /// - Then:
    ///    - there is no prompt, so the authorize request has no `prompt` item
    func testEmptyPromptSendsNoPromptItem() {
        XCTAssertNil(Self.engineOptions(WebUIOptions(prompt: []), configuredScopes: ["openid"]).prompt)
    }

    // MARK: - Transcribed values

    /// `Prompt` has the plugin's cases and raw values.
    ///
    /// - Given: every `WebUIOptions.Prompt` case
    /// - When:
    ///    - their raw values are read
    /// - Then:
    ///    - they are exactly `none`, `login`, `select_account` and `consent`, the plugin's
    ///      `AWSAuthWebUISignInOptions.Prompt` raw values
    func testPromptRawValuesMatchThePlugin() {
        XCTAssertEqual(WebUIOptions.Prompt.allCases.map(\.rawValue), ["none", "login", "select_account", "consent"])
        XCTAssertEqual(WebUIOptions.Prompt(rawValue: "select_account"), .selectAccount)
    }

    /// Each provider reaches the engine as the engine's provider of the same case, whose `userPoolProviderName` is
    /// the plugin's own: the authorize request's `identity_provider` (`LiveEngineWebUITests`).
    ///
    /// - Given: one `AuthClientProvider` of every case
    /// - When:
    ///    - it is mapped to the engine's provider
    /// - Then:
    ///    - each is the same case, and the three named cases pass their name through
    func testProvidersMapToTheEnginesCaseForCase() {
        let expected: [(AuthClientProvider, EngineAuthProvider)] = [
            (.amazon, .amazon),
            (.apple, .apple),
            (.facebook, .facebook),
            (.google, .google),
            (.twitter, .twitter),
            (.oidc("MyOIDC"), .oidc("MyOIDC")),
            (.saml("MySAML"), .saml("MySAML")),
            (.custom("MyCustom"), .custom("MyCustom"))
        ]
        for (provider, engine) in expected {
            // An exhaustive switch with no default, so a new case fails to compile until it is
            // added to the list above.
            switch provider {
            case .amazon, .apple, .facebook, .google, .twitter, .oidc, .saml, .custom:
                XCTAssertEqual(EngineAuthProvider(provider), engine, "\(provider)")
            }
        }
    }

    // MARK: - Busy policy timeout

    /// Timeouts are normalised when the policy is made, so edge values are defined rather than
    /// trapping, and an app's wait is always bounded.
    ///
    /// - Given: `.wait` with ordinary, zero, negative, NaN, sub-nanosecond, huge and infinite timeouts
    /// - When:
    ///    - the policies are compared and `timeoutNanoseconds` is read
    /// - Then:
    ///    - `.fail` has no timeout, and an ordinary timeout converts exactly
    ///    - zero, negative, NaN and sub-nanosecond timeouts are `.fail`
    ///    - huge and infinite timeouts clamp to `maximumWaitTimeout`, one hour
    ///    - only the package-level `waitWithoutBound` has no bound
    func testWaitTimeoutIsNormalisedWhenThePolicyIsMade() {
        typealias Policy = WebUIOptions.BrowserBusyPolicy

        XCTAssertNil(Policy.fail.timeoutNanoseconds)
        XCTAssertEqual(Policy.wait(timeout: 1.5).timeoutNanoseconds, 1_500_000_000)

        XCTAssertEqual(Policy.wait(timeout: 0), .fail)
        XCTAssertEqual(Policy.wait(timeout: -3), .fail)
        XCTAssertEqual(Policy.wait(timeout: .nan), .fail)
        XCTAssertEqual(Policy.wait(timeout: 1e-12), .fail)

        XCTAssertEqual(Policy.maximumWaitTimeout, 3_600)
        XCTAssertEqual(Policy.wait(timeout: 1e30), .wait(timeout: Policy.maximumWaitTimeout))
        XCTAssertEqual(Policy.wait(timeout: .infinity).timeoutNanoseconds, 3_600_000_000_000)

        XCTAssertEqual(Policy.waitWithoutBound.timeoutNanoseconds, .max)
        XCTAssertNotEqual(Policy.waitWithoutBound, .wait(timeout: .infinity))
    }

    /// Equality is reflexive for every policy, NaN included, so `WebUIOptions` equality is too.
    ///
    /// - Given: options built with `.wait(timeout: .nan)`
    /// - When:
    ///    - they are compared with an identical copy
    /// - Then:
    ///    - they are equal
    func testOptionsWithANaNTimeoutEqualThemselves() {
        let options = WebUIOptions(whenBrowserBusy: .wait(timeout: .nan))

        XCTAssertEqual(options, WebUIOptions(whenBrowserBusy: .wait(timeout: .nan)))
        XCTAssertEqual(options.whenBrowserBusy, options.whenBrowserBusy)
    }
}
#endif
