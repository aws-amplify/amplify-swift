//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
@testable import Amplify
@testable import AWSCognitoAuthPlugin
@testable import InternalAWSCognitoAuth

/// One golden stored-format fixture: a value the plugin writes to (or reads from) the keychain, or a
/// persisted component of one.
struct StoredFormatFixture {

    enum Kind: String, Codable {
        /// Written by the generator from a value built in code with today's types, in `.sortedKeys` form.
        case canonical
        /// A canonical fixture's content with every object's keys in reverse-sorted order. Written as text
        /// by the generator, not by `JSONEncoder`.
        case permuted
        /// Hand-written bytes in an older shape that today's decoders must still accept.
        case legacy
        /// Hand-written bytes today's decoders must reject. A decoder that became lenient fails the gate.
        case rejected
    }

    let name: String
    let kind: Kind
    /// The Swift type the bytes decode as, for the manifest.
    let type: String
    /// What the value is, in words. The builder in `StoredFormatFixtures` is the precise parameter list.
    let summary: String
    /// Permuted and legacy only: the canonical fixture the decoded value must re-encode to.
    let reencodesAs: String?

    /// The value built in code, encoded with the production encoder (`JSONEncoder()`). `nil` unless canonical.
    let encodeBuiltValue: (() throws -> Data)?
    /// The field dump of the value built in code (the construction parameters). `nil` unless canonical.
    let constructedFields: (() -> [String: String])?
    /// The field dump decoding is expected to produce.
    let expectedFields: () -> [String: String]
    /// Decodes with the production decoder, throwing on any failure, and dumps the result's fields.
    let decodedFields: (Data) throws -> [String: String]
    /// Decodes with the production decoder and re-encodes the result with the production encoder.
    let decodeAndReencode: (Data) throws -> Data

    var fileName: String { "\(name).json" }

    /// `expected` is what decoding gives back when it differs from `value`: `.custom` decodes as
    /// `.customWithSRP`, and a hosted-UI `authProvider` is never persisted.
    static func canonical<T: Codable>(
        _ name: String,
        _ summary: String,
        _ value: T,
        decodesTo expected: T? = nil
    ) -> StoredFormatFixture {
        StoredFormatFixture(
            name: name,
            kind: .canonical,
            type: String(describing: T.self),
            summary: summary,
            reencodesAs: nil,
            encodeBuiltValue: { try productionEncode(value) },
            constructedFields: { FieldDump.fields(of: value) },
            expectedFields: { FieldDump.fields(of: expected ?? value) },
            decodedFields: { try FieldDump.fields(of: productionDecode(T.self, $0)) },
            decodeAndReencode: { try productionEncode(productionDecode(T.self, $0)) }
        )
    }

    static func legacy<T: Codable>(
        _ name: String,
        _ summary: String,
        decodesTo expected: T,
        reencodesAs canonicalName: String
    ) -> StoredFormatFixture {
        StoredFormatFixture(
            name: name,
            kind: .legacy,
            type: String(describing: T.self),
            summary: summary,
            reencodesAs: canonicalName,
            encodeBuiltValue: nil,
            constructedFields: nil,
            expectedFields: { FieldDump.fields(of: expected) },
            decodedFields: { try FieldDump.fields(of: productionDecode(T.self, $0)) },
            decodeAndReencode: { try productionEncode(productionDecode(T.self, $0)) }
        )
    }

    /// Bytes that must not decode as `T`. The recorded "fields" are the `DecodingError` case, so a change
    /// in why decoding fails is visible too.
    static func rejected<T: Codable>(
        _ name: String,
        _ summary: String,
        as type: T.Type,
        failsWith errorCase: String
    ) -> StoredFormatFixture {
        StoredFormatFixture(
            name: name,
            kind: .rejected,
            type: String(describing: T.self),
            summary: summary,
            reencodesAs: nil,
            encodeBuiltValue: nil,
            constructedFields: nil,
            expectedFields: { ["$error": errorCase] },
            decodedFields: { data in
                do {
                    return try FieldDump.fields(of: productionDecode(T.self, data))
                } catch let error as DecodingError {
                    return ["$error": FieldDump.caseName(of: error)]
                } catch {
                    return ["$error": String(describing: Swift.type(of: error))]
                }
            },
            decodeAndReencode: { try productionEncode(productionDecode(T.self, $0)) }
        )
    }

    /// This fixture with its keys in reverse-sorted order. It must decode to the same fields and
    /// re-encode to this fixture.
    var permuted: StoredFormatFixture {
        StoredFormatFixture(
            name: "permuted-\(name)",
            kind: .permuted,
            type: type,
            summary: "\(summary); keys in reverse-sorted order",
            reencodesAs: name,
            encodeBuiltValue: nil,
            constructedFields: nil,
            expectedFields: expectedFields,
            decodedFields: decodedFields,
            decodeAndReencode: decodeAndReencode
        )
    }

    /// Exactly what `AWSCognitoAuthCredentialStore.encode(object:)` does.
    static func productionEncode(_ value: some Encodable) throws -> Data {
        try JSONEncoder().encode(value)
    }

    /// Exactly what `AWSCognitoAuthCredentialStore.decode(data:)` does, without the store's `try?`.
    static func productionDecode<T: Decodable>(_ type: T.Type, _ data: Data) throws -> T {
        try JSONDecoder().decode(T.self, from: data)
    }
}

/// The stored-format fixture matrix. Every value is built from literals, so
/// the generator is deterministic apart from `JSONEncoder` key order, which the canonical form removes.
enum StoredFormatFixtures {

    // MARK: Literals

    /// `{"sub":"fixture-sub-0001","username":"fixture-user","token_use":"access","exp":1700003600}`
    static let accessToken = "eyJhbGciOiJub25lIiwidHlwIjoiSldUIn0."
        + "eyJzdWIiOiJmaXh0dXJlLXN1Yi0wMDAxIiwidXNlcm5hbWUiOiJmaXh0dXJlLXVzZXIiLCJ0b2tlbl91c2UiOiJhY2Nlc3MiLCJleHAiOjE3MDAwMDM2MDB9"
        + ".fixture-signature"
    /// `{"sub":"fixture-sub-0001","username":"fixture-user","token_use":"id","exp":1700003600}`
    static let idToken = "eyJhbGciOiJub25lIiwidHlwIjoiSldUIn0."
        + "eyJzdWIiOiJmaXh0dXJlLXN1Yi0wMDAxIiwidXNlcm5hbWUiOiJmaXh0dXJlLXVzZXIiLCJ0b2tlbl91c2UiOiJpZCIsImV4cCI6MTcwMDAwMzYwMH0"
        + ".fixture-signature"
    static let refreshToken = "fixture-refresh-token"
    /// 2023-11-14T22:13:20Z, one hour after the tokens' `exp`. The fractional part exercises `Double` output.
    static let tokenExpiration = Date(timeIntervalSince1970: 1_700_003_600.25)
    static let signedInDate = Date(timeIntervalSince1970: 1_700_000_000)
    static let credentialsExpiration = Date(timeIntervalSince1970: 1_700_007_200)
    static let identityID = "us-east-1:00000000-0000-4000-8000-000000000001"

    @available(*, deprecated, message: "Builds tokens through the deprecated public initializer, on purpose")
    static var tokens: AWSCognitoUserPoolTokens {
        AWSCognitoUserPoolTokens(
            idToken: idToken,
            accessToken: accessToken,
            refreshToken: refreshToken,
            expiration: tokenExpiration
        )
    }

    /// `tokens`, as the engine type that `SignedInData` holds. Built from the same
    /// literals, not converted, so the construction check (d) does not depend on the plugin's converter.
    static var engineTokens: EngineUserPoolTokens {
        EngineUserPoolTokens(
            idToken: idToken,
            accessToken: accessToken,
            refreshToken: refreshToken,
            expiration: tokenExpiration
        )
    }

    /// `credentials`, as the engine type that `AmplifyCredentials` holds.
    static var engineCredentials: EngineAWSCredentials {
        EngineAWSCredentials(
            accessKeyId: "FIXTUREACCESSKEYID",
            secretAccessKey: "fixture/secret+access=key",
            sessionToken: "fixture-session-token",
            expiration: credentialsExpiration
        )
    }

    static var credentials: AuthAWSCognitoCredentials {
        AuthAWSCognitoCredentials(
            accessKeyId: "FIXTUREACCESSKEYID",
            secretAccessKey: "fixture/secret+access=key",
            sessionToken: "fixture-session-token",
            expiration: credentialsExpiration
        )
    }

    static var deviceData: DeviceMetadata.Data {
        DeviceMetadata.Data(
            deviceKey: "us-east-1_fixture-device-key",
            deviceGroupKey: "fixture-device-group-key",
            deviceSecret: "fixture-device-secret"
        )
    }

    static let providers: [(String, AuthProvider)] = [
        ("amazon", .amazon),
        ("apple", .apple),
        ("facebook", .facebook),
        ("google", .google),
        ("twitter", .twitter),
        ("oidc", .oidc("fixture-oidc-provider")),
        ("saml", .saml("fixture-saml-provider")),
        ("custom", .custom("fixture.custom.provider"))
    ]

    /// Every `AuthFlowType` value, with its fixture suffix. `.custom` is deprecated and still persisted.
    @available(*, deprecated, message: "Includes the deprecated AuthFlowType.custom, on purpose")
    static var flows: [(String, AuthFlowType)] {
        var flows: [(String, AuthFlowType)] = [
            ("userSRP", .userSRP),
            ("custom", .custom),
            ("customWithSRP", .customWithSRP),
            ("customWithoutSRP", .customWithoutSRP),
            ("userPassword", .userPassword),
            ("userAuth-nil", .userAuth(preferredFirstFactor: nil)),
            ("userAuth-password", .userAuth(preferredFirstFactor: .password)),
            ("userAuth-passwordSRP", .userAuth(preferredFirstFactor: .passwordSRP)),
            ("userAuth-smsOTP", .userAuth(preferredFirstFactor: .smsOTP)),
            ("userAuth-emailOTP", .userAuth(preferredFirstFactor: .emailOTP))
        ]
        #if os(iOS) || os(macOS) || os(visionOS)
        if #available(iOS 17.4, macOS 13.5, visionOS 1.0, *) {
            flows.append(("userAuth-webAuthn", .userAuth(preferredFirstFactor: .webAuthn)))
        }
        #endif
        return flows
    }

    /// Fixtures that exist on disk but whose values can't be built on every platform.
    /// `AuthFactorType.webAuthn` exists only on iOS 17.4+, macOS 13.5+ and visionOS. Generated on macOS.
    static func isPlatformDependent(_ name: String) -> Bool {
        name.hasSuffix("userAuth-webAuthn")
    }

    /// Whether this platform and OS version have `AuthFactorType.webAuthn`, so the fixtures that
    /// `isPlatformDependent(_:)` names can be built and decoded here.
    static var hasPlatformDependentTypes: Bool {
        #if os(iOS) || os(macOS) || os(visionOS)
        if #available(iOS 17.4, macOS 13.5, visionOS 1.0, *) {
            return true
        }
        #endif
        return false
    }

    /// What a flow decodes back to. `.custom` encodes as `CUSTOM_AUTH_WITH_SRP`, which decodes as
    /// `.customWithSRP` (`AuthFlowType.swift:55-56`).
    @available(*, deprecated, message: "Mentions the deprecated AuthFlowType.custom, on purpose")
    static func decodedFlow(_ flow: AuthFlowType) -> AuthFlowType? {
        flow == .custom ? .customWithSRP : nil
    }

    static func hostedUIOptions(
        providerInfo: HostedUIProviderInfo = HostedUIProviderInfo(authProvider: nil, idpIdentifier: nil),
        full: Bool = false
    ) -> HostedUIOptions {
        HostedUIOptions(
            scopes: full ? ["openid", "email", "aws.cognito.signin.user.admin"] : [],
            providerInfo: providerInfo,
            presentationAnchor: nil,
            preferPrivateSession: full,
            nonce: full ? "fixture-nonce" : nil,
            language: full ? "en" : nil,
            loginHint: full ? "fixture-user@example.com" : nil,
            prompt: full ? "login consent" : nil,
            resource: full ? "myapp://resource" : nil
        )
    }

    @available(*, deprecated, message: "Builds tokens through the deprecated public initializer, on purpose")
    static func signedInData(
        signInMethod: SignInMethod = .apiBased(.userSRP),
        deviceMetadata: DeviceMetadata = .noData,
        isRefreshTokenExpired: Bool? = false,
        inputUsername: String? = nil
    ) -> SignedInData {
        var data = SignedInData(
            signedInDate: signedInDate,
            signInMethod: signInMethod,
            deviceMetadata: deviceMetadata,
            cognitoUserPoolTokens: engineTokens,
            inputUsername: inputUsername
        )
        data.isRefreshTokenExpired = isRefreshTokenExpired
        return data
    }

    static var minimalUserPool: UserPoolConfigurationData {
        UserPoolConfigurationData(
            poolId: "us-east-1_FixturePool",
            clientId: "fixture-client-id",
            region: "us-east-1"
        )
    }

    static var fullUserPool: UserPoolConfigurationData {
        UserPoolConfigurationData(
            poolId: "us-east-1_FixturePool",
            clientId: "fixture-client-id",
            region: "us-east-1",
            endpoint: .init(validatedHost: "auth.fixture.example.com"),
            clientSecret: "fixture-client-secret",
            pinpointAppId: "fixture-pinpoint-app-id",
            authFlowType: .userAuth(preferredFirstFactor: .emailOTP),
            hostedUIConfig: HostedUIConfigurationData(
                clientId: "fixture-hosted-ui-client-id",
                oauth: OAuthConfigurationData(
                    domain: "fixture.auth.us-east-1.amazoncognito.com",
                    scopes: ["openid", "email", "phone", "profile", "aws.cognito.signin.user.admin"],
                    signInRedirectURI: "myapp://signin/",
                    signOutRedirectURI: "myapp://signout/"
                ),
                clientSecret: "fixture-hosted-ui-client-secret"
            ),
            passwordProtectionSettings: .init(from: .init(
                minLength: 12,
                requireNumbers: true,
                requireLowercase: true,
                requireUppercase: true,
                requireSymbols: true
            )),
            usernameAttributes: [.username, .email, .phoneNumber],
            signUpAttributes: [
                .address, .birthDate, .email, .familyName, .gender, .givenName, .middleName, .name,
                .nickname, .phoneNumber, .preferredUsername, .profile, .website
            ],
            verificationMechanisms: [.email, .phoneNumber]
        )
    }

    static var identityPool: IdentityPoolConfigurationData {
        IdentityPoolConfigurationData(
            poolId: "us-east-1:00000000-0000-4000-8000-00000000ffff",
            region: "us-east-1"
        )
    }

    // MARK: The matrix

    @available(*, deprecated, message: "Uses deprecated token and flow APIs, on purpose")
    static var all: [StoredFormatFixture] {
        var fixtures: [StoredFormatFixture] = []

        // AuthFlowType, alone and inside SignInMethod.apiBased
        for (suffix, flow) in flows {
            fixtures.append(.canonical("authFlowType-\(suffix)", "AuthFlowType .\(suffix)", flow, decodesTo: decodedFlow(flow)))
        }
        for (suffix, flow) in flows {
            fixtures.append(.canonical(
                "signInMethod-apiBased-\(suffix)",
                "SignInMethod.apiBased(.\(suffix))",
                SignInMethod.apiBased(EngineAuthFlowType(flow)),
                decodesTo: decodedFlow(flow).map { SignInMethod.apiBased(EngineAuthFlowType($0)) }
            ))
        }

        // SignInMethod.hostedUI. HostedUIProviderInfo never persists `authProvider`
        // (`HostedUIProviderInfo.swift:15-30`), so every non-nil provider decodes back as nil.
        fixtures.append(.canonical(
            "signInMethod-hostedUI-minimal",
            "hostedUI: no scopes, no provider, no optional fields",
            SignInMethod.hostedUI(hostedUIOptions())
        ))
        fixtures.append(.canonical(
            "signInMethod-hostedUI-full",
            "hostedUI: scopes, private session, nonce, lang, login_hint, prompt, resource; idpIdentifier only",
            SignInMethod.hostedUI(hostedUIOptions(
                providerInfo: HostedUIProviderInfo(authProvider: nil, idpIdentifier: "fixture-idp"),
                full: true
            ))
        ))
        // One optional at a time, so each key's presence and absence is pinned on its own.
        for (field, options) in hostedUIOptionsWithOneField {
            fixtures.append(.canonical(
                "signInMethod-hostedUI-only-\(field)",
                "hostedUI: minimal apart from \(field)",
                SignInMethod.hostedUI(options)
            ))
        }
        fixtures.append(.canonical(
            "signInMethod-hostedUI-authProvider-dropped",
            "hostedUI built with authProvider .google: it is not persisted and decodes as nil",
            SignInMethod.hostedUI(hostedUIOptions(
                providerInfo: HostedUIProviderInfo(authProvider: .google, idpIdentifier: "fixture-idp"),
                full: true
            )),
            decodesTo: SignInMethod.hostedUI(hostedUIOptions(
                providerInfo: HostedUIProviderInfo(authProvider: nil, idpIdentifier: "fixture-idp"),
                full: true
            ))
        ))

        // Tokens and credentials
        fixtures.append(.canonical("userPoolTokens", "AWSCognitoUserPoolTokens", tokens))
        fixtures.append(.canonical("awsCredentials", "AuthAWSCognitoCredentials", credentials))

        // SignedInData variants
        fixtures.append(.canonical(
            "signedInData-refreshExpired-nil",
            "SignedInData, isRefreshTokenExpired nil, no inputUsername, noData",
            signedInData(isRefreshTokenExpired: nil)
        ))
        fixtures.append(.canonical(
            "signedInData-refreshExpired-true",
            "SignedInData, isRefreshTokenExpired true",
            signedInData(isRefreshTokenExpired: true)
        ))
        fixtures.append(.canonical(
            "signedInData-refreshExpired-false",
            "SignedInData, isRefreshTokenExpired false",
            signedInData(isRefreshTokenExpired: false)
        ))
        fixtures.append(.canonical(
            "signedInData-inputUsername-device",
            "SignedInData with inputUsername and device metadata",
            signedInData(deviceMetadata: .metadata(deviceData), inputUsername: "Fixture.User@Example.com")
        ))
        fixtures.append(.canonical(
            "signedInData-hostedUI",
            "SignedInData signed in through hosted UI",
            signedInData(signInMethod: .hostedUI(hostedUIOptions(
                providerInfo: HostedUIProviderInfo(authProvider: nil, idpIdentifier: "fixture-idp"),
                full: true
            )))
        ))

        // `session`: every AmplifyCredentials case
        fixtures.append(.canonical(
            "session-userPoolOnly",
            "AmplifyCredentials.userPoolOnly",
            AmplifyCredentials.userPoolOnly(signedInData: signedInData(inputUsername: "fixture-user"))
        ))
        fixtures.append(.canonical(
            "session-identityPoolOnly",
            "AmplifyCredentials.identityPoolOnly",
            AmplifyCredentials.identityPoolOnly(identityID: identityID, credentials: engineCredentials)
        ))
        // AuthProvider reaches the keychain only through FederatedToken.provider: synthesized Codable,
        // `{"amazon":{}}` and `{"oidc":{"_0":…}}` shapes.
        for (suffix, provider) in providers {
            fixtures.append(.canonical(
                "session-identityPoolWithFederation-\(suffix)",
                "AmplifyCredentials.identityPoolWithFederation, provider .\(suffix)",
                AmplifyCredentials.identityPoolWithFederation(
                    federatedToken: FederatedToken(token: "fixture-federated-token", provider: EngineAuthProvider(provider)),
                    identityID: identityID,
                    credentials: engineCredentials
                )
            ))
        }
        fixtures.append(.canonical(
            "session-userPoolAndIdentityPool",
            "AmplifyCredentials.userPoolAndIdentityPool, device metadata, userAuth(.smsOTP)",
            AmplifyCredentials.userPoolAndIdentityPool(
                signedInData: signedInData(
                    signInMethod: .apiBased(.userAuth(preferredFirstFactor: .smsOTP)),
                    deviceMetadata: .metadata(deviceData),
                    inputUsername: "fixture-user"
                ),
                identityID: identityID,
                credentials: engineCredentials
            )
        ))
        fixtures.append(.canonical(
            "session-userPoolOnly-customWithSRP",
            "userPoolOnly, customWithSRP, isRefreshTokenExpired and inputUsername nil (the legacy session's re-encoding)",
            AmplifyCredentials.userPoolOnly(signedInData: signedInData(
                signInMethod: .apiBased(.customWithSRP),
                isRefreshTokenExpired: nil
            ))
        ))
        fixtures.append(.canonical("session-noCredentials", "AmplifyCredentials.noCredentials", AmplifyCredentials.noCredentials))

        // `deviceMetadata` and `deviceASF`
        fixtures.append(.canonical("deviceMetadata-metadata", "DeviceMetadata.metadata", DeviceMetadata.metadata(deviceData)))
        fixtures.append(.canonical("deviceMetadata-noData", "DeviceMetadata.noData", DeviceMetadata.noData))
        fixtures.append(.canonical("deviceASF", "ASF device id (a top-level JSON string)", "fixture-asf-device-id"))

        // `authConfiguration`: every case, optionals empty and full
        fixtures.append(.canonical("userPoolConfiguration-minimal", "UserPoolConfigurationData, every optional empty", minimalUserPool))
        fixtures.append(.canonical("userPoolConfiguration-full", "UserPoolConfigurationData, every optional set", fullUserPool))
        fixtures.append(.canonical("authConfiguration-userPools-minimal", "AuthConfiguration.userPools, minimal", AuthConfiguration.userPools(minimalUserPool)))
        fixtures.append(.canonical("authConfiguration-userPools-full", "AuthConfiguration.userPools, full", AuthConfiguration.userPools(fullUserPool)))
        fixtures.append(.canonical(
            "authConfiguration-userPools-userPassword",
            "AuthConfiguration.userPools, minimal apart from authFlowType .userPassword",
            AuthConfiguration.userPools(UserPoolConfigurationData(
                poolId: "us-east-1_FixturePool",
                clientId: "fixture-client-id",
                region: "us-east-1",
                authFlowType: .userPassword
            ))
        ))
        fixtures.append(.canonical("authConfiguration-identityPools", "AuthConfiguration.identityPools", AuthConfiguration.identityPools(identityPool)))
        fixtures.append(.canonical(
            "authConfiguration-userPoolsAndIdentityPools-minimal",
            "AuthConfiguration.userPoolsAndIdentityPools, minimal user pool",
            AuthConfiguration.userPoolsAndIdentityPools(minimalUserPool, identityPool)
        ))
        fixtures.append(.canonical(
            "authConfiguration-userPoolsAndIdentityPools-full",
            "AuthConfiguration.userPoolsAndIdentityPools, full user pool",
            AuthConfiguration.userPoolsAndIdentityPools(fullUserPool, identityPool)
        ))

        // Every canonical fixture with an object of two or more keys also gets a permuted variant.
        fixtures += fixtures.filter { fixture in
            guard let encode = fixture.encodeBuiltValue, let data = try? encode() else { return false }
            return (try? CanonicalJSON.hasMultiKeyObject(data)) ?? false
        }.map(\.permuted)

        fixtures.append(contentsOf: legacy)
        fixtures.append(contentsOf: rejected)
        return fixtures
    }

    static var hostedUIOptionsWithOneField: [(String, HostedUIOptions)] {
        let none = HostedUIProviderInfo(authProvider: nil, idpIdentifier: nil)
        func options(
            scopes: [String] = [],
            providerInfo: HostedUIProviderInfo = none,
            preferPrivateSession: Bool = false,
            nonce: String? = nil,
            language: String? = nil,
            loginHint: String? = nil,
            prompt: String? = nil,
            resource: String? = nil
        ) -> HostedUIOptions {
            HostedUIOptions(
                scopes: scopes,
                providerInfo: providerInfo,
                presentationAnchor: nil,
                preferPrivateSession: preferPrivateSession,
                nonce: nonce,
                language: language,
                loginHint: loginHint,
                prompt: prompt,
                resource: resource
            )
        }
        return [
            ("scopes", options(scopes: ["openid"])),
            ("idpIdentifier", options(providerInfo: HostedUIProviderInfo(authProvider: nil, idpIdentifier: "fixture-idp"))),
            ("preferPrivateSession", options(preferPrivateSession: true)),
            ("nonce", options(nonce: "fixture-nonce")),
            ("language", options(language: "en")),
            ("loginHint", options(loginHint: "fixture-user@example.com")),
            ("prompt", options(prompt: "login")),
            ("resource", options(resource: "myapp://resource"))
        ]
    }

    // MARK: Rejected inputs (hand-written files, never generated)

    static var rejected: [StoredFormatFixture] {
        [
            .rejected(
                "rejected-authFlowType-unknown-factor",
                "USER_AUTH with an unknown preferredFirstFactor",
                as: AuthFlowType.self,
                failsWith: "dataCorrupted"
            ),
            .rejected(
                "rejected-authFlowType-unknown-type",
                "An unknown type",
                as: AuthFlowType.self,
                failsWith: "dataCorrupted"
            ),
            .rejected(
                "rejected-authFlowType-unknown-bare-string",
                "A bare string legacyInit does not know",
                as: AuthFlowType.self,
                failsWith: "dataCorrupted"
            ),
            .rejected(
                "rejected-authFlowType-no-type",
                "An object without the type key",
                as: AuthFlowType.self,
                failsWith: "keyNotFound"
            ),
            .rejected(
                "rejected-authConfiguration-empty",
                "An authConfiguration with neither pool",
                as: AuthConfiguration.self,
                failsWith: "dataCorrupted"
            ),
            .rejected(
                "rejected-session-unknown-case",
                "An AmplifyCredentials case that does not exist",
                as: AmplifyCredentials.self,
                failsWith: "typeMismatch"
            ),
            .rejected(
                "rejected-session-unknown-provider",
                "identityPoolWithFederation with an AuthProvider case that does not exist",
                as: AmplifyCredentials.self,
                failsWith: "typeMismatch"
            ),
            .rejected(
                "rejected-session-missing-username",
                "userPoolOnly whose signedInData has no username",
                as: AmplifyCredentials.self,
                failsWith: "keyNotFound"
            ),
            .rejected(
                "rejected-signInMethod-hostedUI-no-preferPrivateSession",
                "hostedUI without preferPrivateSession, which is decoded with decode, not decodeIfPresent",
                as: SignInMethod.self,
                failsWith: "keyNotFound"
            ),
            .rejected(
                "rejected-deviceMetadata-missing-secret",
                "Device metadata without deviceSecret",
                as: DeviceMetadata.self,
                failsWith: "keyNotFound"
            ),
            .rejected(
                "rejected-userPoolTokens-string-expiration",
                "Tokens whose expiration is a string, not seconds since 2001",
                as: AWSCognitoUserPoolTokens.self,
                failsWith: "typeMismatch"
            ),
            .rejected(
                "rejected-deviceASF-number",
                "An ASF device id that is not a string",
                as: String.self,
                failsWith: "typeMismatch"
            )
        ]
    }


    // MARK: Legacy inputs (hand-written files, never generated)

    @available(*, deprecated, message: "Uses deprecated token and flow APIs, on purpose")
    static var legacy: [StoredFormatFixture] {
        var fixtures: [StoredFormatFixture] = []
        // Pre-passwordless bare strings (`AuthFlowType.swift:69-84, 137-148`)
        let bare: [(String, AuthFlowType, String)] = [
            ("userSRP", .userSRP, "authFlowType-userSRP"),
            ("userPassword", .userPassword, "authFlowType-userPassword"),
            ("custom", .custom, "authFlowType-custom"),
            ("customWithSRP", .customWithSRP, "authFlowType-customWithSRP"),
            ("customWithoutSRP", .customWithoutSRP, "authFlowType-customWithoutSRP")
        ]
        for (raw, flow, canonical) in bare {
            fixtures.append(.legacy(
                "legacy-authFlowType-bare-\(raw)",
                "Pre-passwordless bare string \"\(raw)\"",
                decodesTo: flow,
                reencodesAs: canonical
            ))
        }
        fixtures.append(.legacy(
            "legacy-authFlowType-CUSTOM_AUTH",
            "Object form with type CUSTOM_AUTH",
            decodesTo: AuthFlowType.customWithSRP,
            reencodesAs: "authFlowType-customWithSRP"
        ))
        fixtures.append(.legacy(
            "legacy-authFlowType-USER_AUTH-no-factor-key",
            "USER_AUTH without a preferredFirstFactor key",
            decodesTo: AuthFlowType.userAuth(preferredFirstFactor: nil),
            reencodesAs: "authFlowType-userAuth-nil"
        ))
        fixtures.append(.legacy(
            "legacy-signInMethod-apiBased-bare-userSRP",
            "SignInMethod.apiBased holding a bare \"userSRP\"",
            decodesTo: SignInMethod.apiBased(.userSRP),
            reencodesAs: "signInMethod-apiBased-userSRP"
        ))
        fixtures.append(.legacy(
            "legacy-signInMethod-hostedUI-no-optional-keys",
            "hostedUI with no nonce/lang/login_hint/prompt/resource keys and an empty providerInfo",
            decodesTo: SignInMethod.hostedUI(hostedUIOptions()),
            reencodesAs: "signInMethod-hostedUI-minimal"
        ))
        fixtures.append(.legacy(
            "legacy-session-userPoolOnly-bare-custom",
            "A pre-passwordless session: bare \"custom\" flow, no isRefreshTokenExpired or inputUsername keys",
            decodesTo: AmplifyCredentials.userPoolOnly(signedInData: signedInData(
                signInMethod: .apiBased(.custom),
                isRefreshTokenExpired: nil
            )),
            reencodesAs: "session-userPoolOnly-customWithSRP"
        ))
        fixtures.append(.legacy(
            "legacy-authConfiguration-userPools-bare-userPassword",
            "A pre-passwordless authConfiguration whose authFlowType is a bare \"userPassword\"",
            decodesTo: AuthConfiguration.userPools(UserPoolConfigurationData(
                poolId: "us-east-1_FixturePool",
                clientId: "fixture-client-id",
                region: "us-east-1",
                authFlowType: .userPassword
            )),
            reencodesAs: "authConfiguration-userPools-userPassword"
        ))
        return fixtures
    }
}
