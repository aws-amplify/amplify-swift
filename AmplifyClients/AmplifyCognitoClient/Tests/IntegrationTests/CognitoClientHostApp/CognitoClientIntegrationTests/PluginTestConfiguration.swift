//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

// Shared with CognitoClientUITests, CognitoClientHostedUIApp and CognitoClientPluginInteropTests, which compile
// this file on its own. Keep it self-contained: Foundation only.

import Foundation

/// The plugin's test configuration as the harness hands it to the client: always a Gen2 `amplify_outputs`
/// document, in a bundle, under the plugin's Gen2 file name.
///
/// The client reads Gen2 `amplify_outputs` only, and refuses a Gen1 `amplifyconfiguration.json`. Some of the
/// plugin's CI backends exist only as Gen1 files (`<suite>-amplifyconfiguration.json`, no
/// `<suite>-amplify_outputs.json`). For those, and only when the Gen2 file is absent, the harness translates the
/// Gen1 file into the equivalent Gen2 outputs (`Gen1TestConfiguration.amplifyOutputs(fromGen1:resourceName:)`),
/// writes it under the Gen2 name into a directory of its own, and hands the client that directory as the bundle.
/// The client then loads it exactly as an app loads its `amplify_outputs.json`. This is a test fixture concern:
/// the client itself stays Gen2 only.
enum PluginTestConfiguration {

    /// The plugin's Gen1 file name for the same backend as the Gen2 `outputsResource`, without `.json`:
    /// `<suite>-amplify_outputs` becomes `<suite>-amplifyconfiguration`.
    static func gen1Resource(for outputsResource: String) -> String? {
        let suffix = "-amplify_outputs"
        guard outputsResource.hasSuffix(suffix) else {
            return nil
        }
        return String(outputsResource.dropLast(suffix.count)) + "-amplifyconfiguration"
    }

    /// Whether `bundle` has the Gen2 file `outputsResource`, or the plugin's Gen1 file for the same backend.
    static func isPresent(_ outputsResource: String, in bundle: Bundle) -> Bool {
        source(outputsResource, in: bundle) != nil
    }

    /// Which of the two files `outputsResource` is read from, or nil when neither is in `bundle`. The Gen2
    /// file wins when both are.
    static func source(_ outputsResource: String, in bundle: Bundle) -> Source? {
        if bundle.url(forResource: outputsResource, withExtension: "json") != nil {
            return .gen2(outputsResource)
        }
        if let gen1 = gen1Resource(for: outputsResource), bundle.url(forResource: gen1, withExtension: "json") != nil {
            return .gen1(gen1)
        }
        return nil
    }

    /// The bundle to load the Gen2 `outputsResource` from: `bundle` itself when it has the file, otherwise a
    /// directory holding the translation of the plugin's Gen1 file under the Gen2 name.
    ///
    /// - Throws: `PluginTestConfigurationError` when neither file is in `bundle`, or when the Gen1 file cannot
    ///   be translated (it names something `amplify_outputs` cannot carry).
    static func outputsBundle(_ outputsResource: String, in bundle: Bundle) throws -> Bundle {
        switch source(outputsResource, in: bundle) {
        case .gen2:
            return bundle
        case .gen1(let gen1):
            // A directory of its own per resource, holding only that file, which is written before the directory's
            // bundle is created and rewritten with the same content on every later call. Foundation keeps one
            // `Bundle` per path, so no file is ever added to a directory a bundle has already been made for.
            let directory = FileManager.default.temporaryDirectory
                .appendingPathComponent("cognito-client-translated-outputs", isDirectory: true)
                .appendingPathComponent(outputsResource, isDirectory: true)
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            try outputsData(outputsResource, gen1: gen1, in: bundle)
                .write(to: directory.appendingPathComponent("\(outputsResource).json"), options: .atomic)
            guard let translated = Bundle(url: directory) else {
                throw PluginTestConfigurationError("The translation of \(gen1).json could not be opened as a bundle.")
            }
            return translated
        case nil:
            throw PluginTestConfigurationError(missing: outputsResource)
        }
    }

    /// The Gen2 `outputsResource` document: the file itself, or the translation of the plugin's Gen1 file.
    static func outputsData(_ outputsResource: String, in bundle: Bundle) throws -> Data {
        switch source(outputsResource, in: bundle) {
        case .gen2:
            return try Data(contentsOf: url(outputsResource, in: bundle))
        case .gen1(let gen1):
            return try outputsData(outputsResource, gen1: gen1, in: bundle)
        case nil:
            throw PluginTestConfigurationError(missing: outputsResource)
        }
    }

    private static func outputsData(_ outputsResource: String, gen1: String, in bundle: Bundle) throws -> Data {
        let document = try Gen1TestConfiguration.amplifyOutputs(
            fromGen1: Data(contentsOf: url(gen1, in: bundle)),
            resourceName: gen1
        )
        return try JSONSerialization.data(withJSONObject: document, options: [.sortedKeys])
    }

    private static func url(_ resource: String, in bundle: Bundle) throws -> URL {
        guard let url = bundle.url(forResource: resource, withExtension: "json") else {
            throw PluginTestConfigurationError(missing: resource)
        }
        return url
    }

    /// The file an outputs resource is read from.
    enum Source: Equatable {
        /// The plugin's Gen2 file, read as it is.
        case gen2(String)
        /// The plugin's Gen1 file, translated.
        case gen1(String)
    }
}

/// The translation of the plugin's Gen1 test configuration into the Gen2 `amplify_outputs` the client reads.
///
/// Every key the client reads from `auth` is mapped from where the plugin reads it in Gen1
/// (`ConfigurationHelper.parseUserPoolData(_: JSONValue)`, `parseHostedConfiguration(configuration:)`,
/// `parseIdentityPoolData(_: JSONValue)`), or from the Amplify CLI's `Auth.Default` keys where the plugin reads
/// none. Where Gen1 has no counterpart, the value is the one the plugin's Gen1 path uses:
///
/// | Gen2 key | Gen1 source | When Gen1 has none |
/// |---|---|---|
/// | `aws_region`, `user_pool_id`, `user_pool_client_id` | `CognitoUserPool.Default` `Region`, `PoolId`, `AppClientId` | required, as for the plugin |
/// | `identity_pool_id` | `CredentialsProvider.CognitoIdentity.Default`, only with both `PoolId` and `Region`, as the plugin requires (the `Region` must be the user pool's: Gen2 has one region) | omitted: no identity pool |
/// | `unauthenticated_identities_enabled` | none | omitted ("not stated"): the plugin reads no guest flag in either format, and asks for guest credentials whenever it has an identity pool |
/// | `oauth` | `Auth.Default.OAuth`, only with all of `WebDomain`, `Scopes` (an array; an entry that is not a string becomes `""`, as for the plugin), `AppClientId`, `SignInRedirectURI`, `SignOutRedirectURI`, as the plugin requires. Each redirect URI is the plugin's one URI, as written | omitted: no hosted UI |
/// | `oauth.identity_providers` | `Auth.Default.socialProviders` (`AMAZON`, `APPLE` renamed to `LOGIN_WITH_AMAZON`, `SIGN_IN_WITH_APPLE`) | `[]` |
/// | `oauth.response_type` | none | `code`: the plugin's Gen1 hosted UI always uses the code grant |
/// | `password_policy` | carried from the CLI's `Auth.Default.passwordProtectionSettings` (`passwordPolicyMinLength`, `passwordPolicyCharacters`) | omitted: the plugin's Gen1 path sets none |
/// | `username_attributes` | carried from the CLI's `Auth.Default.usernameAttributes`, lower-cased | omitted: the plugin's Gen1 path sets `[]` |
/// | `standard_required_attributes` | carried from the CLI's `Auth.Default.signupAttributes`, lower-cased | omitted: `[]` |
/// | `user_verification_types` | carried from the CLI's `Auth.Default.verificationMechanisms`, lower-cased | omitted: `[]` |
/// | `mfa_configuration` | carried from the CLI's `Auth.Default.mfaConfiguration` (`OFF`, `OPTIONAL`, `ON` to `NONE`, `OPTIONAL`, `REQUIRED`; any other value is refused) | omitted ("not stated") |
/// | `mfa_methods` | carried from the CLI's `Auth.Default.mfaTypes` | omitted: `[]` |
/// | `data` | the first GraphQL API of `api.plugins.awsAPIPlugin` (`endpoint`, `region`, `authorizationType`, `apiKey`); other API types are skipped | omitted: no code API |
///
/// The rows "carried from the CLI's" keys are ones the plugin's Gen1 path does not read, and nothing in the client
/// acts on them either: the client only exposes them on its configuration. The harness reads `mfa_methods`, to
/// name an MFA type a role's backend lacks.
///
/// Not carried, because Gen2 has no key for it: `PinpointAppId`. Refused, because the client would run without them
/// and fail far from the cause: an `AppClientSecret` on the user pool or on the hosted UI (the plugin sends the
/// latter with its token exchange), a custom `Endpoint`, an OAuth `AppClientId` other than the user pool's, an
/// identity pool in another region, an `authenticationFlowType` other than `USER_SRP_AUTH`, and `MigrationEnabled`
/// (both change the plugin's default flow, which the client takes as SRP, as for Gen2 outputs).
enum Gen1TestConfiguration {

    /// The Gen2 `amplify_outputs` document equivalent to the Gen1 `amplifyconfiguration.json` in `data`.
    ///
    /// - Parameter resourceName: The Gen1 file's name without `.json`, for the error messages.
    static func amplifyOutputs(fromGen1 data: Data, resourceName: String) throws -> [String: Any] {
        func fail(_ problem: String) -> PluginTestConfigurationError {
            PluginTestConfigurationError("\(resourceName).json \(problem)")
        }
        guard let document = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw fail("is not a JSON object.")
        }
        guard let plugin = value(document, "auth", "plugins", "awsCognitoAuthPlugin") as? [String: Any] else {
            throw fail("has no auth.plugins.awsCognitoAuthPlugin section: it is not the plugin's Gen1 configuration.")
        }
        guard let userPool = value(plugin, "CognitoUserPool", "Default") as? [String: Any] else {
            throw fail("has no CognitoUserPool.Default: the client needs a user pool.")
        }
        func required(_ key: String) throws -> String {
            guard let text = userPool[key] as? String, !text.isEmpty else {
                throw fail("has no CognitoUserPool.Default.\(key).")
            }
            return text
        }
        let region = try required("Region")
        let poolId = try required("PoolId")
        let appClientId = try required("AppClientId")
        var auth: [String: Any] = [
            "aws_region": region,
            "user_pool_id": poolId,
            "user_pool_client_id": appClientId
        ]
        if userPool["AppClientSecret"] != nil {
            throw fail("names an AppClientSecret, which amplify_outputs cannot carry: the client would sign every request without it.")
        }
        if userPool["Endpoint"] != nil {
            throw fail("names a custom user pool Endpoint, which amplify_outputs cannot carry.")
        }
        if userPool["MigrationEnabled"] as? Bool == true {
            throw fail("""
            enables MigrationEnabled, which makes the plugin sign in with USER_PASSWORD_AUTH; amplify_outputs cannot \
            carry it, and the client's sign-ins default to SRP.
            """)
        }

        // As the plugin: an identity pool needs both its id and its region.
        if let identityPool = value(plugin, "CredentialsProvider", "CognitoIdentity", "Default") as? [String: Any],
           let identityPoolId = identityPool["PoolId"] as? String, !identityPoolId.isEmpty,
           let identityRegion = identityPool["Region"] as? String {
            guard identityRegion == region else {
                throw fail("puts its identity pool in another region than its user pool, which amplify_outputs cannot express.")
            }
            auth["identity_pool_id"] = identityPoolId
        }

        let settings = value(plugin, "Auth", "Default") as? [String: Any] ?? [:]
        if let flow = settings["authenticationFlowType"] as? String, flow != "USER_SRP_AUTH" {
            throw fail("""
            sets Auth.Default.authenticationFlowType "\(flow)", the plugin's default flow; amplify_outputs cannot \
            carry it, and the client's sign-ins default to SRP.
            """)
        }
        if let oauth = try oauth(settings, appClientId: appClientId, fail: fail) {
            auth["oauth"] = oauth
        }
        if let policy = settings["passwordProtectionSettings"] as? [String: Any] {
            auth["password_policy"] = try passwordPolicy(policy, fail: fail)
        }
        for (gen1Key, gen2Key) in [
            ("usernameAttributes", "username_attributes"),
            ("signupAttributes", "standard_required_attributes"),
            ("verificationMechanisms", "user_verification_types")
        ] {
            if let values = settings[gen1Key] as? [String], !values.isEmpty {
                auth[gen2Key] = values.map { $0.lowercased() }
            }
        }
        if let mode = settings["mfaConfiguration"] as? String {
            guard let mapped = ["OFF": "NONE", "OPTIONAL": "OPTIONAL", "ON": "REQUIRED"][mode.uppercased()] else {
                throw fail("has an unknown Auth.Default.mfaConfiguration \"\(mode)\".")
            }
            auth["mfa_configuration"] = mapped
        }
        if let types = settings["mfaTypes"] as? [String], !types.isEmpty {
            auth["mfa_methods"] = types.map { $0.uppercased() }
        }

        var outputs: [String: Any] = ["version": "1", "auth": auth]
        if let api = graphQLAPI(document) {
            outputs["data"] = api
        }
        return outputs
    }

    private static func oauth(
        _ settings: [String: Any],
        appClientId: String,
        fail: (String) -> PluginTestConfigurationError
    ) throws -> [String: Any]? {
        guard let oauth = settings["OAuth"] as? [String: Any],
              let domain = oauth["WebDomain"] as? String,
              let scopes = oauth["Scopes"] as? [Any],
              let oauthClientId = oauth["AppClientId"] as? String,
              let signIn = oauth["SignInRedirectURI"] as? String,
              let signOut = oauth["SignOutRedirectURI"] as? String else {
            return nil
        }
        guard oauthClientId == appClientId else {
            throw fail("names another app client for its hosted UI than for its user pool; amplify_outputs has one.")
        }
        if oauth["AppClientSecret"] != nil {
            throw fail("""
            names an OAuth AppClientSecret, which amplify_outputs cannot carry: the plugin sends it with the hosted \
            UI's token exchange, and the client would exchange without it.
            """)
        }
        let providers = ["AMAZON": "LOGIN_WITH_AMAZON", "APPLE": "SIGN_IN_WITH_APPLE"]
        return [
            "domain": domain,
            // As the plugin: an entry that is not a string becomes "".
            "scopes": scopes.map { $0 as? String ?? "" },
            "redirect_sign_in_uri": [signIn],
            "redirect_sign_out_uri": [signOut],
            "identity_providers": (settings["socialProviders"] as? [String] ?? []).map { providers[$0.uppercased()] ?? $0.uppercased() },
            "response_type": "code"
        ]
    }

    private static func passwordPolicy(
        _ policy: [String: Any],
        fail: (String) -> PluginTestConfigurationError
    ) throws -> [String: Any] {
        let minLength: Int
        switch policy["passwordPolicyMinLength"] {
        case let number as NSNumber:
            minLength = number.intValue
        case let text as String:
            guard let parsed = Int(text) else {
                throw fail("has a non-numeric Auth.Default.passwordProtectionSettings.passwordPolicyMinLength.")
            }
            minLength = parsed
        default:
            throw fail("has no Auth.Default.passwordProtectionSettings.passwordPolicyMinLength.")
        }
        let characters = Set((policy["passwordPolicyCharacters"] as? [String] ?? []).map { $0.uppercased() })
        return [
            "min_length": minLength,
            "require_lowercase": characters.contains("REQUIRES_LOWERCASE"),
            "require_uppercase": characters.contains("REQUIRES_UPPERCASE"),
            "require_numbers": characters.contains("REQUIRES_NUMBERS"),
            "require_symbols": characters.contains("REQUIRES_SYMBOLS")
        ]
    }

    /// The first GraphQL API, by name, of the Gen1 `api` category, as a Gen2 `data` block.
    private static func graphQLAPI(_ document: [String: Any]) -> [String: Any]? {
        guard let apis = value(document, "api", "plugins", "awsAPIPlugin") as? [String: Any] else {
            return nil
        }
        for name in apis.keys.sorted() {
            guard let api = apis[name] as? [String: Any],
                  (api["endpointType"] as? String)?.caseInsensitiveCompare("GraphQL") == .orderedSame,
                  let url = api["endpoint"] as? String,
                  let region = api["region"] as? String else {
                continue
            }
            var data: [String: Any] = [
                "aws_region": region,
                "url": url,
                "default_authorization_type": api["authorizationType"] as? String ?? "API_KEY",
                "authorization_types": [String]()
            ]
            if let apiKey = api["apiKey"] as? String {
                data["api_key"] = apiKey
            }
            return data
        }
        return nil
    }

    private static func value(_ object: [String: Any], _ path: String...) -> Any? {
        var current: Any? = object
        for key in path {
            current = (current as? [String: Any])?[key]
        }
        return current
    }
}

/// A test configuration file that is missing or cannot be translated. The message names the file.
struct PluginTestConfigurationError: Error, CustomStringConvertible {
    let description: String

    init(_ description: String) {
        self.description = description
    }

    /// Neither the Gen2 file nor, where the plugin has one, its Gen1 file for the same backend is in the bundle.
    init(missing outputsResource: String) {
        if let gen1 = PluginTestConfiguration.gen1Resource(for: outputsResource) {
            self.init("Neither \(outputsResource).json nor its Gen1 \(gen1).json is in the bundle.")
        } else {
            self.init("\(outputsResource).json is not in the bundle.")
        }
    }
}
