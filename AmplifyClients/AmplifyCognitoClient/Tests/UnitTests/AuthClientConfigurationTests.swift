//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
@_spi(AmplifyExperimental) @testable import AmplifyCognitoClient

final class AuthClientConfigurationTests: XCTestCase {

    private func outputs(_ auth: [String: Any]?) throws -> Data {
        var document: [String: Any] = ["version": "1.4"]
        if let auth { document["auth"] = auth }
        return try JSONSerialization.data(withJSONObject: document)
    }

    private let fullAuth: [String: Any] = [
        "aws_region": "us-east-1",
        "user_pool_id": "us-east-1_AbC",
        "user_pool_client_id": "client123",
        "identity_pool_id": "us-east-1:0000-1111"
    ]

    /// - Given: an `amplify_outputs` document with both pools
    /// - When: parsed
    /// - Then:
    ///    - both pools are populated, sharing the document's region
    func testParsesBothPools() throws {
        let config = try AuthClientConfiguration(outputsData: outputs(fullAuth), resourceName: "amplify_outputs")
        XCTAssertEqual(config.userPool, .init(poolId: "us-east-1_AbC", appClientId: "client123", region: "us-east-1"))
        XCTAssertEqual(config.identityPool, .init(poolId: "us-east-1:0000-1111", region: "us-east-1"))
    }

    /// - Given: a document with no identity pool, and one with an empty identity pool ID
    /// - When: parsed
    /// - Then:
    ///    - both yield a user-pool-only configuration
    func testIdentityPoolIsOptional() throws {
        var auth = fullAuth
        auth["identity_pool_id"] = nil
        XCTAssertNil(try AuthClientConfiguration(outputsData: outputs(auth), resourceName: "x").identityPool)
        auth["identity_pool_id"] = ""
        XCTAssertNil(try AuthClientConfiguration(outputsData: outputs(auth), resourceName: "x").identityPool)
    }

    /// Each missing key must be named in the error, so a developer knows what to fix.
    ///
    /// - Given: documents each missing one required key
    /// - When: parsed
    /// - Then:
    ///    - each throws `configuration` naming that key
    func testMissingRequiredKeyIsNamed() throws {
        for key in ["aws_region", "user_pool_id", "user_pool_client_id"] {
            var auth = fullAuth
            auth[key] = nil
            XCTAssertThrowsError(try AuthClientConfiguration(outputsData: outputs(auth), resourceName: "x"), key) { error in
                guard case AuthClientError.configuration(let description, _, _) = error else {
                    return XCTFail("Expected configuration error, got \(error)")
                }
                XCTAssertTrue(description.contains("auth.\(key)"), description)
            }
        }
    }

    /// - Given: a document with no `auth` section, and bytes that are not JSON
    /// - When: parsed
    /// - Then:
    ///    - each throws `configuration`
    func testMissingAuthSectionAndInvalidJSONThrow() throws {
        XCTAssertThrowsError(try AuthClientConfiguration(outputsData: outputs(nil), resourceName: "x"))
        XCTAssertThrowsError(try AuthClientConfiguration(outputsData: Data("not json".utf8), resourceName: "x"))
    }

    /// A Gen1 file is refused as Gen1, not as a Gen2 file missing a key.
    ///
    /// - Given: a Gen1 `amplifyconfiguration.json` document (`auth.plugins.awsCognitoAuthPlugin`), with its
    ///   user pool and identity pool
    /// - When: parsed
    /// - Then:
    ///    - it throws `configuration` saying Gen1 is not supported and pointing to Gen2 `amplify_outputs`,
    ///      naming the resource and no missing key
    func testGen1ConfigurationIsRefusedAsGen1() throws {
        let gen1: [String: Any] = [
            "UserAgent": "aws-amplify-cli/2.0",
            "Version": "1.0",
            "auth": [
                "plugins": [
                    "awsCognitoAuthPlugin": [
                        "CognitoUserPool": ["Default": [
                            "PoolId": "us-east-1_AbC",
                            "AppClientId": "client123",
                            "Region": "us-east-1"
                        ]],
                        "CredentialsProvider": ["CognitoIdentity": ["Default": [
                            "PoolId": "us-east-1:0000-1111",
                            "Region": "us-east-1"
                        ]]]
                    ]
                ]
            ]
        ]
        let data = try JSONSerialization.data(withJSONObject: gen1)

        XCTAssertThrowsError(try AuthClientConfiguration(outputsData: data, resourceName: "amplifyconfiguration")) { error in
            guard case AuthClientError.configuration(let description, let suggestion, _) = error else {
                return XCTFail("Expected configuration error, got \(error)")
            }
            XCTAssertEqual(
                description,
                "amplifyconfiguration.json is a Gen1 configuration, which AmplifyCognitoClient does not support."
            )
            XCTAssertTrue(suggestion.contains("Gen2 amplify_outputs.json"), suggestion)
            XCTAssertFalse(description.contains("missing"), description)
        }
        XCTAssertThrowsError(try AuthClientConfiguration(outputsData: data, resourceName: "config")) { error in
            XCTAssertEqual(
                (error as? AuthClientError)?.errorDescription,
                "config.json (an amplifyconfiguration.json) is a Gen1 configuration, which AmplifyCognitoClient does not support."
            )
        }
    }

    /// Only a file shaped like Gen1 is refused as Gen1.
    ///
    /// - Given: a Gen2 document whose `auth` section also carries a `plugins` dictionary; and one whose
    ///   `plugins` dictionary sits beside a missing `user_pool_id` but a present `aws_region`
    /// - When: parsed
    /// - Then:
    ///    - the first parses as Gen2, both pools read; the second throws the Gen2 missing-key error for
    ///      `auth.user_pool_id`, not the Gen1 one
    func testAGen2FileWithAPluginsKeyIsReadAsGen2() throws {
        var auth = fullAuth
        auth["plugins"] = ["awsCognitoAuthPlugin": [:] as [String: Any]]
        let config = try AuthClientConfiguration(outputsData: outputs(auth), resourceName: "amplify_outputs")
        XCTAssertEqual(config.userPool?.poolId, "us-east-1_AbC")
        XCTAssertEqual(config.identityPool?.poolId, "us-east-1:0000-1111")

        auth["user_pool_id"] = nil
        XCTAssertThrowsError(try AuthClientConfiguration(outputsData: outputs(auth), resourceName: "x")) { error in
            guard case AuthClientError.configuration(let description, _, _) = error else {
                return XCTFail("Expected configuration error, got \(error)")
            }
            XCTAssertTrue(description.contains("auth.user_pool_id"), description)
            XCTAssertFalse(description.contains("Gen1"), description)
        }
    }

    /// - Given: a resource name that includes the `.json` extension
    /// - When: loaded from a bundle
    /// - Then:
    ///    - it throws before looking the file up, rather than failing with a confusing not-found
    func testResourceNameWithExtensionIsRejected() {
        XCTAssertThrowsError(try AuthClientConfiguration(from: "amplify_outputs.json", bundle: .main)) { error in
            guard case AuthClientError.configuration(let description, _, _) = error else {
                return XCTFail("Expected configuration error, got \(error)")
            }
            XCTAssertTrue(description.contains("extension"), description)
        }
    }

    /// - Given: no pools
    /// - When: constructed programmatically
    /// - Then:
    ///    - it throws, so `poolNamespace` can never be asked of an empty configuration
    func testRequiresAtLeastOnePool() {
        XCTAssertThrowsError(try AuthClientConfiguration(userPool: nil, identityPool: nil))
    }

    /// The namespace must match what the plugin already writes, or `.default` and a rolled-back plugin
    /// both miss the plugin's record.
    ///
    /// - Given: each of the three pool combinations
    /// - When: the pool namespace is derived
    /// - Then:
    ///    - it matches the plugin's key shape for that combination
    func testPoolNamespaceMatchesEachShape() throws {
        let userPool = AuthClientConfiguration.UserPool(poolId: "up", appClientId: "c", region: "r")
        let identityPool = AuthClientConfiguration.IdentityPool(poolId: "ip", region: "r")
        XCTAssertEqual(try AuthClientConfiguration(userPool: userPool).poolNamespace, .userPool("up"))
        XCTAssertEqual(try AuthClientConfiguration(identityPool: identityPool).poolNamespace, .identityPool("ip"))
        XCTAssertEqual(
            try AuthClientConfiguration(userPool: userPool, identityPool: identityPool).poolNamespace,
            .userPoolAndIdentityPool(userPoolId: "up", identityPoolId: "ip")
        )
    }

    // MARK: The settings beyond the pool identifiers

    private var settingsAuth: [String: Any] {
        var auth = fullAuth
        auth["password_policy"] = [
            "min_length": 10, "require_numbers": true, "require_lowercase": true,
            "require_uppercase": false, "require_symbols": true
        ]
        auth["oauth"] = [
            "identity_providers": ["GOOGLE", "SIGN_IN_WITH_APPLE"],
            "domain": "app.auth.us-east-1.amazoncognito.com",
            "scopes": ["openid", "email"],
            "redirect_sign_in_uri": ["app://in/", "https://example.com/in"],
            "redirect_sign_out_uri": ["app://out/"],
            "response_type": "code"
        ]
        auth["standard_required_attributes"] = ["email", "locale", "birthdate", "zoneinfo"]
        auth["username_attributes"] = ["phone_number"]
        auth["user_verification_types"] = ["email", "phone_number"]
        auth["unauthenticated_identities_enabled"] = true
        auth["mfa_configuration"] = "REQUIRED"
        auth["mfa_methods"] = ["TOTP", "SMS", "EMAIL"]
        return auth
    }

    /// Test that every optional `auth` key is kept, including what the engine does not use
    ///
    /// - Given: An `amplify_outputs` document with every optional `auth` key
    /// - When:
    ///    - It is parsed
    /// - Then:
    ///    - Each setting holds the file's values, in file order: every redirect URI, the identity
    ///      providers, the response type, every standard attribute, the MFA settings and guest access
    ///
    func testParsesEveryOptionalSetting() throws {
        let config = try AuthClientConfiguration(outputsData: outputs(settingsAuth), resourceName: "x")
        let userPool = try XCTUnwrap(config.userPool)
        XCTAssertEqual(userPool.oauth, .init(
            domain: "app.auth.us-east-1.amazoncognito.com",
            scopes: ["openid", "email"],
            redirectSignInURIs: ["app://in/", "https://example.com/in"],
            redirectSignOutURIs: ["app://out/"],
            identityProviders: ["GOOGLE", "SIGN_IN_WITH_APPLE"],
            responseType: "code"
        ))
        XCTAssertEqual(userPool.passwordPolicy, .init(
            minLength: 10, requiresLowercase: true, requiresUppercase: false, requiresNumbers: true, requiresSymbols: true
        ))
        XCTAssertEqual(userPool.standardRequiredAttributes, [.email, .locale, .birthDate, .zoneInfo])
        XCTAssertEqual(userPool.usernameAttributes, [.phoneNumber])
        XCTAssertEqual(userPool.verificationMechanisms, [.email, .phoneNumber])
        XCTAssertEqual(userPool.mfaEnforcement, .required)
        XCTAssertEqual(userPool.mfaMethods, [.totp, .sms, .email])
        XCTAssertNil(userPool.appClientSecret)
        XCTAssertEqual(config.identityPool?.unauthenticatedIdentitiesEnabled, true)
    }

    /// Test that absent optional keys leave the settings empty
    ///
    /// - Given: An `amplify_outputs` document with only the required keys
    /// - When:
    ///    - It is parsed
    /// - Then:
    ///    - The optional settings are `nil` or empty, and guest access is not stated
    ///
    func testAbsentOptionalSettingsAreEmpty() throws {
        let config = try AuthClientConfiguration(outputsData: outputs(fullAuth), resourceName: "x")
        let userPool = try XCTUnwrap(config.userPool)
        XCTAssertNil(userPool.oauth)
        XCTAssertNil(userPool.passwordPolicy)
        XCTAssertNil(userPool.mfaEnforcement)
        XCTAssertEqual(userPool.usernameAttributes, [])
        XCTAssertEqual(userPool.standardRequiredAttributes, [])
        XCTAssertEqual(userPool.verificationMechanisms, [])
        XCTAssertEqual(userPool.mfaMethods, [])
        XCTAssertNil(config.identityPool?.unauthenticatedIdentitiesEnabled)
    }

    /// Test that an invalid optional setting is a configuration error naming the key
    ///
    /// - Given: Documents each with one optional key the plugin's decoder rejects too: an attribute or
    ///   verification type outside the schema, a `password_policy` or `oauth` without one of its keys, and a
    ///   key of the wrong type (including the MFA keys, whose unknown values are otherwise ignored)
    /// - When:
    ///    - Each is parsed
    /// - Then:
    ///    - Each throws `configuration`, and the description names the key in the file's spelling
    ///
    func testInvalidOptionalSettingIsNamed() throws {
        var passwordPolicy = try XCTUnwrap(settingsAuth["password_policy"] as? [String: Any])
        passwordPolicy["min_length"] = nil
        var oauth = try XCTUnwrap(settingsAuth["oauth"] as? [String: Any])
        oauth["redirect_sign_in_uri"] = nil
        let cases: [(key: String, value: Any, named: String)] = [
            ("username_attributes", ["username"], "auth.username_attributes"),
            ("user_verification_types", ["sms"], "auth.user_verification_types"),
            ("standard_required_attributes", ["email_verified"], "auth.standard_required_attributes"),
            ("mfa_configuration", 1, "auth.mfa_configuration"),
            ("mfa_methods", "TOTP", "auth.mfa_methods"),
            ("password_policy", passwordPolicy, "auth.password_policy.min_length"),
            ("oauth", oauth, "auth.oauth.redirect_sign_in_uri"),
            ("unauthenticated_identities_enabled", "yes", "auth.unauthenticated_identities_enabled"),
            ("identity_pool_id", 42, "auth.identity_pool_id")
        ]
        for (key, value, named) in cases {
            var auth = settingsAuth
            auth[key] = value
            XCTAssertThrowsError(try AuthClientConfiguration(outputsData: outputs(auth), resourceName: "x"), key) { error in
                guard case AuthClientError.configuration(let description, _, _) = error else {
                    return XCTFail("Expected configuration error, got \(error)")
                }
                XCTAssertTrue(description.contains(named), "\(key): \(description)")
            }
        }
    }

    /// Test that MFA values this client does not know are ignored, as the plugin ignores them
    ///
    /// - Given: A document whose `mfa_configuration` and some `mfa_methods` entries are outside today's schema,
    ///   as a newer `amplify_outputs` schema could write them
    /// - When:
    ///    - It is parsed
    /// - Then:
    ///    - Parsing succeeds; the unknown enforcement reads as `nil`, and only the known methods are kept, in order
    ///
    func testUnknownMFAValuesAreIgnored() throws {
        var auth = settingsAuth
        auth["mfa_configuration"] = "ADAPTIVE"
        auth["mfa_methods"] = ["PASSKEY", "TOTP", "totp", "EMAIL"]
        let userPool = try XCTUnwrap(AuthClientConfiguration(outputsData: outputs(auth), resourceName: "x").userPool)
        XCTAssertNil(userPool.mfaEnforcement)
        XCTAssertEqual(userPool.mfaMethods, [.totp, .email])
    }

    /// Test that a programmatic configuration accepts only Cognito standard attributes as required
    ///
    /// - Given: User pools whose `standardRequiredAttributes` holds a verification flag, a custom attribute
    ///   or an unknown key
    /// - When:
    ///    - A configuration is constructed with each
    /// - Then:
    ///    - Each throws `configuration`; every one of the eighteen standard attributes is accepted
    ///
    func testStandardRequiredAttributesMustBeStandard() throws {
        for key in [AuthClientUserAttributeKey.emailVerified, .phoneNumberVerified, .custom("team"), .unknown("x")] {
            let userPool = AuthClientConfiguration.UserPool(
                poolId: "p", appClientId: "c", region: "r", standardRequiredAttributes: [key]
            )
            XCTAssertThrowsError(try AuthClientConfiguration(userPool: userPool), "\(key)") { error in
                guard case AuthClientError.configuration = error else {
                    return XCTFail("Expected configuration error, got \(error)")
                }
            }
        }
        let all = Array(AuthClientConfiguration.standardAttributes.values)
        XCTAssertEqual(all.count, 18)
        XCTAssertNoThrow(try AuthClientConfiguration(userPool: .init(
            poolId: "p", appClientId: "c", region: "r", standardRequiredAttributes: all
        )))
    }

    /// Test the engine input the client derives, beyond what the goldens exercise
    ///
    /// - Given: A programmatic user pool with an app client secret and OAuth, and one read from a file
    /// - When:
    ///    - Their engine input is derived
    /// - Then:
    ///    - The flow is `.userSRP`, there is no endpoint and no Pinpoint app
    ///    - The user pool keeps the app client's secret, but the hosted UI has none, as the plugin builds it,
    ///      and it has the first redirect URI of each list
    ///    - Only the engine's thirteen sign-up attributes are kept, in order
    ///
    func testEngineInputDefaultsAndHostedUISecret() throws {
        let userPool = AuthClientConfiguration.UserPool(
            poolId: "p",
            appClientId: "c",
            region: "r",
            appClientSecret: "secret",
            oauth: .init(domain: "d", scopes: ["openid"], redirectSignInURIs: ["a://1", "a://2"], redirectSignOutURIs: ["b://1"])
        )
        let settings = EngineUserPoolSettings(userPool)
        XCTAssertEqual(settings.authFlowType, .userSRP)
        XCTAssertNil(settings.endpoint)
        XCTAssertNil(settings.pinpointAppId)
        XCTAssertEqual(settings.clientSecret, "secret")
        XCTAssertEqual(settings.hostedUIConfig, .init(
            clientId: "c",
            oauth: .init(domain: "d", scopes: ["openid"], signInRedirectURI: "a://1", signOutRedirectURI: "b://1"),
            clientSecret: nil
        ))

        let parsed = try XCTUnwrap(AuthClientConfiguration(outputsData: outputs(settingsAuth), resourceName: "x").userPool)
        XCTAssertEqual(EngineUserPoolSettings(parsed).signUpAttributes, [.email, .birthDate])
        XCTAssertNotNil(EngineUserPoolSettings(parsed).hostedUIConfig)
        XCTAssertNil(EngineUserPoolSettings(parsed).hostedUIConfig?.clientSecret)
    }

    /// - Given: a user pool with an app client secret, alone and in a configuration, and a pool without one
    /// - When: they are printed with `String(describing:)`, `String(reflecting:)`, interpolation and `dump()`
    /// - Then:
    ///    - the secret never appears, and is shown as `<redacted>`; a pool without one shows `nil`
    ///    - the pool ID and app client ID appear only masked as the engine masks them (four characters kept at
    ///      each end), and the region is `<REDACTED>`
    ///    - the other settings still appear
    func testTheAppClientSecretIsRedactedInEveryPrintedForm() throws {
        let userPool = AuthClientConfiguration.UserPool(
            poolId: "us-west-2_EXAMPLEPOOL",
            appClientId: "exampleclientid123",
            region: "us-west-2",
            appClientSecret: "APP-CLIENT-SECRET",
            oauth: .init(domain: "d", scopes: ["openid"], redirectSignInURIs: ["a://1"], redirectSignOutURIs: ["b://1"])
        )
        let configuration = try AuthClientConfiguration(userPool: userPool)
        for value in [userPool, configuration, Optional(userPool) as Any] as [Any] {
            var dumped = ""
            dump(value, to: &dumped)
            for text in [String(describing: value), String(reflecting: value), "\(value)", dumped] {
                for identifier in ["APP-CLIENT-SECRET", "us-west-2_EXAMPLEPOOL", "exampleclientid123", "us-west-2"] {
                    XCTAssertFalse(text.contains(identifier), "\(identifier) in \(text)")
                }
                for shown in ["<redacted>", "us-w****POOL", "exam****d123", "<REDACTED>", "openid"] {
                    XCTAssertTrue(text.contains(shown), "\(shown) missing from \(text)")
                }
            }
        }
        let withoutSecret = AuthClientConfiguration.UserPool(poolId: "p", appClientId: "c", region: "r")
        XCTAssertTrue(String(describing: withoutSecret).contains("appClientSecret: nil"), String(describing: withoutSecret))
        XCTAssertEqual(userPool.appClientSecret, "APP-CLIENT-SECRET")
    }

    /// The stored properties of `UserPool`, in declaration order, as a tuple type: a struct is laid out as the
    /// tuple of its stored properties' types, so a stored property added to `UserPool` changes its layout and no
    /// longer matches this.
    private typealias UserPoolStoredProperties = (
        String, // poolId
        String, // appClientId
        String, // region
        String?, // appClientSecret
        AuthClientConfiguration.OAuth?, // oauth
        AuthClientConfiguration.PasswordPolicy?, // passwordPolicy
        [AuthClientConfiguration.UsernameAttribute], // usernameAttributes
        [AuthClientUserAttributeKey], // standardRequiredAttributes
        [AuthClientConfiguration.VerificationMechanism], // verificationMechanisms
        AuthClientConfiguration.MFAEnforcement?, // mfaEnforcement
        [AuthClientMFAType] // mfaMethods
    )

    private static let userPoolStoredPropertyNames = [
        "poolId", "appClientId", "region", "appClientSecret", "oauth", "passwordPolicy", "usernameAttributes",
        "standardRequiredAttributes", "verificationMechanisms", "mfaEnforcement", "mfaMethods"
    ]

    /// Field-list drift: a stored property added to `UserPool` must be added to its printed forms.
    ///
    /// - Given: the stored properties listed above, as a tuple type and as names
    /// - When: `UserPool`'s layout is compared with the tuple's, and the names with the custom mirror's labels
    ///   and the description
    /// - Then:
    ///    - the layouts match, so the list is every stored property (a new property, of any type with a size,
    ///      breaks this; update the list and `printedFields` together)
    ///    - the mirror has exactly these labels, in order, and the description names each
    func testThePrintedFormsListEveryStoredPropertyOfTheUserPool() {
        XCTAssertEqual(MemoryLayout<AuthClientConfiguration.UserPool>.size, MemoryLayout<UserPoolStoredProperties>.size)
        XCTAssertEqual(MemoryLayout<AuthClientConfiguration.UserPool>.stride, MemoryLayout<UserPoolStoredProperties>.stride)
        XCTAssertEqual(MemoryLayout<AuthClientConfiguration.UserPool>.alignment, MemoryLayout<UserPoolStoredProperties>.alignment)

        let userPool = AuthClientConfiguration.UserPool(poolId: "p", appClientId: "c", region: "r")
        XCTAssertEqual(Mirror(reflecting: userPool).children.map(\.label), Self.userPoolStoredPropertyNames.map { Optional($0) })
        let description = String(describing: userPool)
        for property in Self.userPoolStoredPropertyNames {
            XCTAssertTrue(description.contains("\(property): "), "\(property) missing from \(description)")
        }
    }

    // MARK: - Masked printed forms of the identity pool and OAuth

    /// Every printed form of `value`: `description`, `debugDescription`, interpolation and `dump`.
    private func printedForms(_ value: Any) -> [String] {
        var dumped = ""
        dump(value, to: &dumped)
        return [String(describing: value), String(reflecting: value), "\(value)", dumped]
    }

    private static let oauth = AuthClientConfiguration.OAuth(
        domain: "example-domain.auth.us-west-2.amazoncognito.com",
        scopes: ["openid", "email"],
        redirectSignInURIs: ["exampleapp://signin/callback", "exampleapp://second/signin"],
        redirectSignOutURIs: ["exampleapp://signout/callback"],
        identityProviders: ["GOOGLE"],
        responseType: "code"
    )

    /// - Given: an identity pool, alone and in a configuration
    /// - When: it is printed with `String(describing:)`, `String(reflecting:)`, interpolation and `dump()`
    /// - Then:
    ///    - the pool ID appears only masked as the engine's `IdentityPoolConfigurationData` masks it (four
    ///      characters kept at each end), and the region is `<REDACTED>`
    ///    - the guest flag still appears, and the stored values are unchanged
    func testIdentityPoolPrintsMasked() throws {
        let identityPool = AuthClientConfiguration.IdentityPool(
            poolId: "us-west-2:11111111-2222-3333-4444-555555555555",
            region: "us-west-2",
            unauthenticatedIdentitiesEnabled: true
        )
        let configuration = try AuthClientConfiguration(identityPool: identityPool)
        for value in [identityPool, configuration, Optional(identityPool) as Any] as [Any] {
            for text in printedForms(value) {
                for identifier in ["us-west-2:11111111-2222-3333-4444-555555555555", "11111111", "us-west-2"] {
                    XCTAssertFalse(text.contains(identifier), "\(identifier) in \(text)")
                }
                for shown in ["us-w****5555", "<REDACTED>", "unauthenticatedIdentitiesEnabled", "true"] {
                    XCTAssertTrue(text.contains(shown), "\(shown) missing from \(text)")
                }
            }
        }
        XCTAssertEqual(String(describing: identityPool), "IdentityPool(poolId: us-w****5555, region: <REDACTED>, unauthenticatedIdentitiesEnabled: true)")
        let unstated = AuthClientConfiguration.IdentityPool(poolId: "p", region: "r")
        XCTAssertTrue(String(describing: unstated).contains("unauthenticatedIdentitiesEnabled: nil"), String(describing: unstated))
        XCTAssertEqual(identityPool.poolId, "us-west-2:11111111-2222-3333-4444-555555555555")
        XCTAssertEqual(identityPool.region, "us-west-2")
    }

    /// - Given: hosted UI settings with a domain and redirect URIs
    /// - When: they are printed with `String(describing:)`, `String(reflecting:)`, interpolation and `dump()`
    /// - Then:
    ///    - the domain and every redirect URI appear only masked as the engine's `OAuthConfigurationData` masks
    ///      them (four characters kept at each end)
    ///    - the scopes, identity providers and response type still appear, and the stored values are unchanged
    func testOAuthPrintsMasked() {
        let oauth = Self.oauth
        for value in [oauth, Optional(oauth) as Any] as [Any] {
            for text in printedForms(value) {
                for identifier in ["example-domain", "amazoncognito", "signin/callback", "signout/callback", "second/signin"] {
                    XCTAssertFalse(text.contains(identifier), "\(identifier) in \(text)")
                }
                for shown in ["exam****.com", "exam****back", "exam****gnin", "openid", "email", "GOOGLE", "code"] {
                    XCTAssertTrue(text.contains(shown), "\(shown) missing from \(text)")
                }
            }
        }
        XCTAssertEqual(oauth.domain, "example-domain.auth.us-west-2.amazoncognito.com")
        XCTAssertEqual(oauth.redirectSignInURIs, ["exampleapp://signin/callback", "exampleapp://second/signin"])
    }

    /// The stored properties of `IdentityPool` and of `OAuth`, in declaration order, as tuple types (see
    /// `UserPoolStoredProperties`).
    private typealias IdentityPoolStoredProperties = (
        String, // poolId
        String, // region
        Bool? // unauthenticatedIdentitiesEnabled
    )

    private typealias OAuthStoredProperties = (
        String, // domain
        [String], // scopes
        [String], // redirectSignInURIs
        [String], // redirectSignOutURIs
        [String], // identityProviders
        String // responseType
    )

    private static let identityPoolStoredPropertyNames = ["poolId", "region", "unauthenticatedIdentitiesEnabled"]

    private static let oauthStoredPropertyNames = [
        "domain", "scopes", "redirectSignInURIs", "redirectSignOutURIs", "identityProviders", "responseType"
    ]

    /// Field-list drift: a stored property added to `IdentityPool` or `OAuth` must be added to its printed forms.
    ///
    /// - Given: the stored properties listed above, as tuple types and as names
    /// - When: each type's layout is compared with its tuple's, and the names with the custom mirror's labels and
    ///   the description
    /// - Then:
    ///    - the layouts match, so each list is every stored property (a new property breaks this; update the list
    ///      and `printedFields` together)
    ///    - each mirror has exactly these labels, in order, and each description names each
    func testThePrintedFormsListEveryStoredPropertyOfTheIdentityPoolAndOAuth() {
        typealias IdentityPool = AuthClientConfiguration.IdentityPool
        typealias OAuth = AuthClientConfiguration.OAuth
        XCTAssertEqual(MemoryLayout<IdentityPool>.size, MemoryLayout<IdentityPoolStoredProperties>.size)
        XCTAssertEqual(MemoryLayout<IdentityPool>.stride, MemoryLayout<IdentityPoolStoredProperties>.stride)
        XCTAssertEqual(MemoryLayout<IdentityPool>.alignment, MemoryLayout<IdentityPoolStoredProperties>.alignment)
        XCTAssertEqual(MemoryLayout<OAuth>.size, MemoryLayout<OAuthStoredProperties>.size)
        XCTAssertEqual(MemoryLayout<OAuth>.stride, MemoryLayout<OAuthStoredProperties>.stride)
        XCTAssertEqual(MemoryLayout<OAuth>.alignment, MemoryLayout<OAuthStoredProperties>.alignment)

        let printed: [(Any, [String])] = [
            (IdentityPool(poolId: "p", region: "r"), Self.identityPoolStoredPropertyNames),
            (Self.oauth, Self.oauthStoredPropertyNames)
        ]
        for (value, names) in printed {
            XCTAssertEqual(Mirror(reflecting: value).children.map(\.label), names.map { Optional($0) })
            let description = String(describing: value)
            for property in names {
                XCTAssertTrue(description.contains("\(property): "), "\(property) missing from \(description)")
            }
        }
    }

    /// - Given: a user pool with hosted UI settings, alone and in a configuration
    /// - When: it is printed with `String(describing:)`, `String(reflecting:)`, interpolation and `dump()`
    /// - Then:
    ///    - its `oauth` prints through the masked form: no domain or redirect URI appears in full, and the masked
    ///      domain and the scopes do
    func testUserPoolPrintsItsOAuthMasked() throws {
        let userPool = AuthClientConfiguration.UserPool(poolId: "p", appClientId: "c", region: "r", oauth: Self.oauth)
        let configuration = try AuthClientConfiguration(userPool: userPool)
        for value in [userPool, configuration] as [Any] {
            for text in printedForms(value) {
                for identifier in ["example-domain", "amazoncognito", "signin/callback", "signout/callback"] {
                    XCTAssertFalse(text.contains(identifier), "\(identifier) in \(text)")
                }
                for shown in ["oauth", "exam****.com", "openid"] {
                    XCTAssertTrue(text.contains(shown), "\(shown) missing from \(text)")
                }
            }
        }
    }
}
