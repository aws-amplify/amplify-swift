//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

#if os(iOS) || os(macOS) || os(visionOS)
import Foundation
import XCTest
@_spi(AmplifyExperimental) @testable import AmplifyCognitoClient

/// Pins `WebUIOptions` to the plugin's hosted-UI options.
///
/// This target cannot import Amplify, so the plugin's values are transcribed, citing the file they
/// came from:
///
/// - `AmplifyPlugins/Auth/Sources/AWSCognitoAuthPlugin/Models/Options/AWSAuthWebUISignInOptions.swift`
///   (fields, `Prompt`)
/// - `AmplifyPlugins/Auth/Sources/AWSCognitoAuthPlugin/Support/HostedUI/HostedUIRequestHelper.swift`
///   (query item names and order)
/// - `AmplifyClients/Internal/InternalAWSCognitoAuth/Sources/Support/Helpers/AuthProvider+Cognito.swift`
///   (`userPoolProviderName`)
final class WebUIOptionsTests: XCTestCase {

    private static func dictionary(_ items: [URLQueryItem]) -> [String: String?] {
        Dictionary(uniqueKeysWithValues: items.map { ($0.name, $0.value) })
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

    /// Defaults contribute only the configured scopes to the authorize request.
    ///
    /// - Given: `WebUIOptions()`
    /// - When:
    ///    - its query items are built against configured scopes `["openid", "email"]`
    /// - Then:
    ///    - the only item is `scope`, sorted and space-separated
    func testDefaultsContributeOnlyTheConfiguredScopes() {
        let items = WebUIOptions().authorizeQueryItems(configuredScopes: ["openid", "email"])

        XCTAssertEqual(items, [URLQueryItem(name: "scope", value: "email openid")])
    }

    // MARK: - Query items

    /// Every parity field reaches the authorize request under the plugin's name, in its order.
    ///
    /// - Given: options with every field set, and `idpIdentifier` absent so `provider` applies
    /// - When:
    ///    - the query items are built
    /// - Then:
    ///    - the names and values match `HostedUIRequestHelper.createSignInURL`, in its append order
    func testEveryFieldMapsToThePluginsQueryItemInThePluginsOrder() {
        let options = WebUIOptions(
            scopes: ["profile", "openid"],
            provider: .google,
            nonce: "n-123",
            language: "fr",
            loginHint: "alice@example.com",
            prompt: [.login, .selectAccount],
            resource: "myapp://resource"
        )

        let items = options.authorizeQueryItems(configuredScopes: ["ignored"])

        XCTAssertEqual(items, [
            URLQueryItem(name: "scope", value: "openid profile"),
            URLQueryItem(name: "identity_provider", value: "Google"),
            URLQueryItem(name: "nonce", value: "n-123"),
            URLQueryItem(name: "lang", value: "fr"),
            URLQueryItem(name: "login_hint", value: "alice@example.com"),
            URLQueryItem(name: "prompt", value: "login select_account"),
            URLQueryItem(name: "resource", value: "myapp://resource")
        ])
    }

    /// `idpIdentifier` wins over `provider`, as in the plugin.
    ///
    /// - Given: options with both `idpIdentifier` and `provider`
    /// - When:
    ///    - the query items are built
    /// - Then:
    ///    - `idp_identifier` is sent and `identity_provider` is not
    func testIdpIdentifierTakesPrecedenceOverProvider() {
        let options = WebUIOptions(provider: .saml("Okta"), idpIdentifier: "corp.example.com")

        let items = Self.dictionary(options.authorizeQueryItems(configuredScopes: ["openid"]))

        XCTAssertEqual(items["idp_identifier"], "corp.example.com")
        XCTAssertFalse(items.keys.contains("identity_provider"))
    }

    /// Explicit scopes replace the configured ones rather than adding to them, including an empty list.
    ///
    /// - Given: options with `scopes: []`
    /// - When:
    ///    - the query items are built against non-empty configured scopes
    /// - Then:
    ///    - `scope` is empty, as `request.options.scopes ?? configured` produces in the plugin
    func testExplicitScopesReplaceTheConfiguredScopes() {
        let items = WebUIOptions(scopes: []).authorizeQueryItems(configuredScopes: ["openid"])

        XCTAssertEqual(items, [URLQueryItem(name: "scope", value: "")])
    }

    /// An empty prompt list sends nothing, the one documented divergence from the plugin.
    ///
    /// - Given: options with `prompt: []`
    /// - When:
    ///    - the query items are built
    /// - Then:
    ///    - there is no `prompt` item
    func testEmptyPromptSendsNoPromptItem() {
        let items = Self.dictionary(WebUIOptions(prompt: []).authorizeQueryItems(configuredScopes: ["openid"]))

        XCTAssertFalse(items.keys.contains("prompt"))
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

    /// Provider names match the plugin's `userPoolProviderName`.
    ///
    /// - Given: one `AuthClientProvider` of every case
    /// - When:
    ///    - `userPoolProviderName` is read
    /// - Then:
    ///    - each matches the plugin's string, and the three named cases pass their name through
    func testProviderNamesMatchThePlugin() {
        let expected: [(AuthClientProvider, String)] = [
            (.amazon, "LoginWithAmazon"),
            (.apple, "SignInWithApple"),
            (.facebook, "Facebook"),
            (.google, "Google"),
            (.twitter, "Twitter"),
            (.oidc("MyOIDC"), "MyOIDC"),
            (.saml("MySAML"), "MySAML"),
            (.custom("MyCustom"), "MyCustom")
        ]
        for (provider, name) in expected {
            // An exhaustive switch with no default, so a new case fails to compile until it is
            // added to the list above.
            switch provider {
            case .amazon, .apple, .facebook, .google, .twitter, .oidc, .saml, .custom:
                XCTAssertEqual(provider.userPoolProviderName, name, "\(provider)")
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
