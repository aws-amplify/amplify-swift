//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

@_spi(AmplifyExperimental) import AmplifyCognitoClient
import Foundation
import XCTest

/// The harness's reading of the plugin's test configuration (`PluginTestConfiguration`): a Gen2 file as it is,
/// and a Gen1 file, where the plugin's CI has only that, translated into the equivalent Gen2 outputs. No
/// backend is called; the documents are made up, with made-up identifiers. Each test uses resource names of its
/// own, so its bundle directories and the translation's directory are its own, and are removed at teardown.
final class PluginTestConfigurationTests: XCTestCase {

    private var directories: [URL] = []
    /// This test's suite name: its resources are `<suite>-amplifyconfiguration` and `<suite>-amplify_outputs`.
    private var suite = ""

    private var gen1: String { "\(suite)-amplifyconfiguration" }
    private var gen2: String { "\(suite)-amplify_outputs" }

    override func setUp() async throws {
        try await super.setUp()
        suite = "Suite\(UUID().uuidString.replacingOccurrences(of: "-", with: "").prefix(12))"
        // Where `outputsBundle` writes this test's translation.
        directories.append(FileManager.default.temporaryDirectory
            .appendingPathComponent("cognito-client-translated-outputs", isDirectory: true)
            .appendingPathComponent(gen2, isDirectory: true))
    }

    override func tearDown() async throws {
        for directory in directories {
            try? FileManager.default.removeItem(at: directory)
        }
        directories = []
        try await super.tearDown()
    }

    /// Every Gen1 key the client has a Gen2 counterpart for is carried over, and the client loads the result.
    ///
    /// - Given: A Gen1 configuration in the Amplify CLI's shape, with a user pool, an identity pool in the same
    ///   region, a hosted UI on the same app client, the `Auth.Default` settings and a GraphQL API
    /// - When:
    ///    - It is translated, and the client loads the translation from the bundle `outputsBundle` returns
    /// - Then:
    ///    - The pools, the region, the hosted UI (with the plugin's code grant and the renamed social
    ///      providers), the password policy, the username, sign-up and verification attributes and the MFA
    ///      mode and types are the Gen1 file's
    ///    - The API becomes the `data` block, and no guest flag is stated
    ///
    func testGen1ConfigurationTranslatesToTheEquivalentOutputs() throws {
        let bundle = try makeBundle([gen1: Self.gen1(settings: Self.fullSettings, api: true)])

        let outputs = try Self.document(PluginTestConfiguration.outputsData(gen2, in: bundle))
        let configuration = try AuthClientConfiguration(
            from: gen2,
            bundle: PluginTestConfiguration.outputsBundle(gen2, in: bundle)
        )

        let userPool = try XCTUnwrap(configuration.userPool)
        XCTAssertEqual(userPool.poolId, "us-west-2_Pool")
        XCTAssertEqual(userPool.appClientId, "client")
        XCTAssertEqual(userPool.region, "us-west-2")
        XCTAssertNil(userPool.appClientSecret)
        XCTAssertEqual(userPool.oauth, AuthClientConfiguration.OAuth(
            domain: "example.auth.us-west-2.amazoncognito.com",
            scopes: ["openid", "email"],
            redirectSignInURIs: ["myapp://"],
            redirectSignOutURIs: ["myapp://"],
            identityProviders: ["GOOGLE", "LOGIN_WITH_AMAZON", "SIGN_IN_WITH_APPLE"],
            responseType: "code"
        ))
        XCTAssertEqual(userPool.passwordPolicy, AuthClientConfiguration.PasswordPolicy(
            minLength: 10,
            requiresLowercase: true,
            requiresUppercase: false,
            requiresNumbers: true,
            requiresSymbols: false
        ))
        XCTAssertEqual(userPool.usernameAttributes, [.email])
        XCTAssertEqual(userPool.standardRequiredAttributes, [.email, .phoneNumber])
        XCTAssertEqual(userPool.verificationMechanisms, [.email])
        XCTAssertEqual(userPool.mfaEnforcement, .required)
        XCTAssertEqual(userPool.mfaMethods, [.sms, .totp])
        XCTAssertEqual(configuration.identityPool, .init(poolId: "us-west-2:identity", region: "us-west-2"))

        let auth = try XCTUnwrap(outputs["auth"] as? [String: Any])
        XCTAssertNil(auth["unauthenticated_identities_enabled"], "Gen1 states no guest flag")
        let data = try XCTUnwrap(outputs["data"] as? [String: Any])
        XCTAssertEqual(data["url"] as? String, "https://example.appsync-api.us-west-2.amazonaws.com/graphql")
        XCTAssertEqual(data["api_key"] as? String, "made-up-key")
        XCTAssertEqual(data["aws_region"] as? String, "us-west-2")
        XCTAssertEqual(data["default_authorization_type"] as? String, "API_KEY")
    }

    /// A Gen1 file that states only what the plugin's Gen1 path reads gets that path's values for the rest.
    ///
    /// - Given: A Gen1 configuration with only `CognitoUserPool.Default` and the SRP `authenticationFlowType`
    /// - When:
    ///    - The client loads its translation
    /// - Then:
    ///    - It has the user pool and nothing else: no identity pool, hosted UI or password policy, no
    ///      attributes, MFA mode or types, and no `data` block (the SRP flow type needs no Gen2 key)
    ///
    func testGen1TranslationUsesThePluginDefaultsForAbsentKeys() throws {
        let bundle = try makeBundle([gen1: Self.gen1(settings: ["authenticationFlowType": "USER_SRP_AUTH"], identityPool: nil)])

        let outputs = try Self.document(PluginTestConfiguration.outputsData(gen2, in: bundle))
        let configuration = try AuthClientConfiguration(
            from: gen2,
            bundle: PluginTestConfiguration.outputsBundle(gen2, in: bundle)
        )

        XCTAssertEqual(configuration.userPool, .init(poolId: "us-west-2_Pool", appClientId: "client", region: "us-west-2"))
        XCTAssertNil(configuration.identityPool)
        XCTAssertEqual(Set(try XCTUnwrap(outputs["auth"] as? [String: Any]).keys), ["aws_region", "user_pool_id", "user_pool_client_id"])
        XCTAssertNil(outputs["data"])
    }

    /// The values the plugin tolerates in Gen1 are read as it reads them, and settings are mapped value by value.
    ///
    /// - Given: Gen1 configurations with an identity pool without a region, a hosted UI with a scope that is not
    ///   a string, a hosted UI missing its sign-out redirect, each MFA mode, a minimum password length written as
    ///   a string, and only a REST API
    /// - When:
    ///    - Each is translated
    /// - Then:
    ///    - No identity pool, as the plugin (it needs both id and region); the scope becomes `""`, as the plugin
    ///      maps it, and the rest of the hosted UI is kept; no hosted UI at all for the incomplete block, as the
    ///      plugin; `OFF` and `OPTIONAL` become `NONE` and `OPTIONAL`; the string length is read as a number; and
    ///      no `data` block for the REST API
    ///
    func testGen1TranslationReadsWhatThePluginTolerates() throws {
        let noRegion = try auth(Self.gen1(settings: [:], identityPool: ["PoolId": "us-west-2:identity"]))
        XCTAssertNil(noRegion["identity_pool_id"], "an identity pool with no region")

        var scopes = Self.oauth(clientId: "client")
        scopes["Scopes"] = ["openid", 7] as [Any]
        let oauth = try XCTUnwrap(try auth(Self.gen1(settings: ["OAuth": scopes]))["oauth"] as? [String: Any])
        XCTAssertEqual(oauth["scopes"] as? [String], ["openid", ""])
        XCTAssertEqual(oauth["domain"] as? String, "example.auth.us-west-2.amazoncognito.com")

        var incomplete = Self.oauth(clientId: "client")
        incomplete["SignOutRedirectURI"] = nil
        XCTAssertNil(try auth(Self.gen1(settings: ["OAuth": incomplete]))["oauth"], "an OAuth block without a sign-out URI")

        for (mode, expected) in [("OFF", "NONE"), ("OPTIONAL", "OPTIONAL"), ("ON", "REQUIRED")] {
            XCTAssertEqual(try auth(Self.gen1(settings: ["mfaConfiguration": mode]))["mfa_configuration"] as? String, expected, mode)
        }

        let policy = try auth(Self.gen1(settings: ["passwordProtectionSettings": [
            "passwordPolicyMinLength": "12", "passwordPolicyCharacters": ["REQUIRES_SYMBOLS"]
        ] as [String: Any]]))["password_policy"] as? [String: Any]
        XCTAssertEqual(policy?["min_length"] as? Int, 12)
        XCTAssertEqual(policy?["require_symbols"] as? Bool, true)
        XCTAssertEqual(policy?["require_lowercase"] as? Bool, false)

        var rest = Self.gen1(settings: [:])
        rest["api"] = ["plugins": ["awsAPIPlugin": ["rest": [
            "endpointType": "REST", "endpoint": "https://example.com/prod", "region": "us-west-2", "authorizationType": "AWS_IAM"
        ]]]]
        XCTAssertNil(try Gen1TestConfiguration.amplifyOutputs(
            fromGen1: JSONSerialization.data(withJSONObject: rest),
            resourceName: gen1
        )["data"], "a REST API is not a code API")
    }

    /// What `amplify_outputs` cannot carry is refused with the Gen1 file's name, not dropped.
    ///
    /// - Given: Gen1 configurations with an app client secret on the user pool and on the hosted UI, a custom
    ///   endpoint, a hosted UI on another app client, an identity pool in another region, a non-SRP flow type,
    ///   migration enabled, an unknown MFA mode, a password policy without a minimum length or with a
    ///   non-numeric one, and a document that is not the plugin's Gen1 shape
    /// - When:
    ///    - Each is translated
    /// - Then:
    ///    - Each throws, naming the file and the reason
    ///
    func testGen1TranslationRefusesWhatOutputsCannotCarry() throws {
        var oauthSecret = Self.oauth(clientId: "client")
        oauthSecret["AppClientSecret"] = "made-up"
        let refused: [(String, [String: Any])] = [
            ("names an AppClientSecret", Self.gen1(settings: [:], userPool: ["AppClientSecret": "made-up"])),
            ("names an OAuth AppClientSecret", Self.gen1(settings: ["OAuth": oauthSecret])),
            ("Endpoint", Self.gen1(settings: [:], userPool: ["Endpoint": "https://example.com"])),
            ("another app client", Self.gen1(settings: ["OAuth": Self.oauth(clientId: "other")])),
            ("another region", Self.gen1(settings: [:], identityPool: ["PoolId": "us-west-2:identity", "Region": "us-east-1"])),
            ("authenticationFlowType \"USER_PASSWORD_AUTH\"", Self.gen1(settings: ["authenticationFlowType": "USER_PASSWORD_AUTH"])),
            ("authenticationFlowType \"CUSTOM_AUTH\"", Self.gen1(settings: ["authenticationFlowType": "CUSTOM_AUTH"])),
            ("MigrationEnabled", Self.gen1(settings: [:], userPool: ["MigrationEnabled": true])),
            ("unknown Auth.Default.mfaConfiguration \"SOMETIMES\"", Self.gen1(settings: ["mfaConfiguration": "SOMETIMES"])),
            ("has no Auth.Default.passwordProtectionSettings.passwordPolicyMinLength", Self.gen1(settings: [
                "passwordProtectionSettings": ["passwordPolicyCharacters": [String]()]
            ])),
            ("non-numeric", Self.gen1(settings: ["passwordProtectionSettings": ["passwordPolicyMinLength": "eight"]])),
            ("awsCognitoAuthPlugin", ["auth": ["aws_region": "us-west-2"]])
        ]
        for (reason, document) in refused {
            XCTAssertThrowsError(try auth(document), reason) { error in
                let message = String(describing: error)
                XCTAssertTrue(message.hasPrefix("\(gen1).json "), message)
                XCTAssertTrue(message.contains(reason), "\(reason): \(message)")
            }
        }
        // `MigrationEnabled: false` changes nothing, as for the plugin.
        XCTAssertNoThrow(try auth(Self.gen1(settings: [:], userPool: ["MigrationEnabled": false])))
    }

    /// The Gen2 file wins when both are present, the Gen1 file is read only without it, and a missing role
    /// is named with both files.
    ///
    /// - Given: Bundles with both files, with the Gen1 file only, and with neither
    /// - When:
    ///    - Each is resolved
    /// - Then:
    ///    - Both: the Gen2 file, from the bundle itself, byte for byte
    ///    - Gen1 only: the Gen1 file, from another bundle holding the translation under the Gen2 name
    ///    - Neither: an error naming the Gen2 file and its Gen1 name
    ///
    func testResolutionPrefersGen2AndNamesBothFilesWhenMissing() throws {
        let gen2Data = try JSONSerialization.data(withJSONObject: [
            "version": "1",
            "auth": ["aws_region": "us-west-2", "user_pool_id": "us-west-2_Gen2", "user_pool_client_id": "gen2"]
        ])
        let both = try makeBundle([gen1: Self.gen1(settings: [:])], raw: [gen2: gen2Data])
        let gen1Only = try makeBundle([gen1: Self.gen1(settings: [:])])
        let neither = try makeBundle([:])

        XCTAssertEqual(PluginTestConfiguration.source(gen2, in: both), .gen2(gen2))
        XCTAssertTrue(try PluginTestConfiguration.outputsBundle(gen2, in: both) === both)
        XCTAssertEqual(try PluginTestConfiguration.outputsData(gen2, in: both), gen2Data)

        XCTAssertEqual(PluginTestConfiguration.source(gen2, in: gen1Only), .gen1(gen1))
        let translated = try PluginTestConfiguration.outputsBundle(gen2, in: gen1Only)
        XCTAssertFalse(translated === gen1Only)
        XCTAssertNotNil(translated.url(forResource: gen2, withExtension: "json"))

        XCTAssertFalse(PluginTestConfiguration.isPresent(gen2, in: neither))
        XCTAssertThrowsError(try PluginTestConfiguration.outputsBundle(gen2, in: neither)) { error in
            XCTAssertEqual(String(describing: error), "Neither \(gen2).json nor its Gen1 \(gen1).json is in the bundle.")
        }
    }

    // MARK: - Fixtures

    private static var fullSettings: [String: Any] {
        [
            "authenticationFlowType": "USER_SRP_AUTH",
            "socialProviders": ["GOOGLE", "AMAZON", "APPLE"],
            "usernameAttributes": ["EMAIL"],
            "signupAttributes": ["EMAIL", "PHONE_NUMBER"],
            "passwordProtectionSettings": [
                "passwordPolicyMinLength": 10,
                "passwordPolicyCharacters": ["REQUIRES_LOWERCASE", "REQUIRES_NUMBERS"]
            ] as [String: Any],
            "mfaConfiguration": "ON",
            "mfaTypes": ["SMS", "TOTP"],
            "verificationMechanisms": ["EMAIL"],
            "OAuth": oauth(clientId: "client")
        ]
    }

    private static func oauth(clientId: String) -> [String: Any] {
        [
            "WebDomain": "example.auth.us-west-2.amazoncognito.com",
            "AppClientId": clientId,
            "SignInRedirectURI": "myapp://",
            "SignOutRedirectURI": "myapp://",
            "Scopes": ["openid", "email"]
        ]
    }

    /// A Gen1 `amplifyconfiguration.json` in the Amplify CLI's shape. `identityPool` is the
    /// `CredentialsProvider.CognitoIdentity.Default` object, or nil for none.
    private static func gen1(
        settings: [String: Any],
        userPool extraUserPool: [String: Any] = [:],
        identityPool: [String: Any]? = ["PoolId": "us-west-2:identity", "Region": "us-west-2"],
        api: Bool = false
    ) -> [String: Any] {
        var plugin: [String: Any] = [
            "UserAgent": "aws-amplify/cli",
            "Version": "0.1.0",
            "IdentityManager": ["Default": [String: Any]()],
            "CognitoUserPool": ["Default": (["PoolId": "us-west-2_Pool", "AppClientId": "client", "Region": "us-west-2"] as [String: Any])
                .merging(extraUserPool) { $1 }],
            "Auth": ["Default": settings]
        ]
        if let identityPool {
            plugin["CredentialsProvider"] = ["CognitoIdentity": ["Default": identityPool]]
        }
        var document: [String: Any] = ["UserAgent": "aws-amplify-cli/2.0", "Version": "1.0", "auth": ["plugins": ["awsCognitoAuthPlugin": plugin]]]
        if api {
            document["api"] = ["plugins": ["awsAPIPlugin": ["codes": [
                "endpointType": "GraphQL",
                "endpoint": "https://example.appsync-api.us-west-2.amazonaws.com/graphql",
                "region": "us-west-2",
                "authorizationType": "API_KEY",
                "apiKey": "made-up-key"
            ]]]]
        }
        return document
    }

    /// The `auth` section of `document`'s translation, named as this test's Gen1 file.
    private func auth(_ document: [String: Any]) throws -> [String: Any] {
        let outputs = try Gen1TestConfiguration.amplifyOutputs(
            fromGen1: JSONSerialization.data(withJSONObject: document),
            resourceName: gen1
        )
        return try XCTUnwrap(outputs["auth"] as? [String: Any])
    }

    private static func document(_ data: Data) throws -> [String: Any] {
        try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
    }

    /// A bundle over a new directory holding `documents` (serialized) and `raw` files, each `<name>.json`.
    private func makeBundle(_ documents: [String: [String: Any]], raw: [String: Data] = [:]) throws -> Bundle {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent("ccit-config-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        directories.append(directory)
        for (name, document) in documents {
            try JSONSerialization.data(withJSONObject: document).write(to: directory.appendingPathComponent("\(name).json"))
        }
        for (name, data) in raw {
            try data.write(to: directory.appendingPathComponent("\(name).json"))
        }
        return try XCTUnwrap(Bundle(url: directory))
    }
}
