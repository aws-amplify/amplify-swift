//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import InternalAWSCognitoAuth

// Plugin-internal access to the engine's credential and configuration values, for the AuthHostApp
// integration target.
//
// The host app is an Xcode project outside the SwiftPM package. It reaches the plugin through
// `@testable import AWSCognitoAuthPlugin`, but it is compiled without the package's `-package-name`, so
// it cannot name a `package` declaration of `InternalAWSCognitoAuth`: not the type, not a
// case, not a member. It can still hold and compare engine values without naming them, and it can call the
// plugin's internal declarations. So it goes through these helpers, which only convert, case for case.
// `HostAppEngineAccessTests` round-trips every case, and `scripts/m2/host_app_probe.sh` type-checks the
// host-app files against the plugin's build.

/// `AmplifyCredentials` as the host app sees it: the same cases, labels and payloads. The signed-in data is
/// wrapped in ``HostAppSignedInData`` so that its members can be read.
enum HostAppCredentials: Equatable {
    case userPoolOnly(signedInData: HostAppSignedInData)
    case identityPoolOnly(identityID: String, credentials: EngineAWSCredentials)
    case identityPoolWithFederation(
        federatedToken: FederatedToken,
        identityID: String,
        credentials: EngineAWSCredentials
    )
    case userPoolAndIdentityPool(
        signedInData: HostAppSignedInData,
        identityID: String,
        credentials: EngineAWSCredentials
    )
    case noCredentials

    /// The host-app value of engine credentials, as read from `AWSCognitoAuthCredentialStore`.
    init(_ credentials: AmplifyCredentials) {
        switch credentials {
        case .userPoolOnly(let signedInData):
            self = .userPoolOnly(signedInData: HostAppSignedInData(signedInData))
        case .identityPoolOnly(let identityID, let credentials):
            self = .identityPoolOnly(identityID: identityID, credentials: credentials)
        case .identityPoolWithFederation(let federatedToken, let identityID, let credentials):
            self = .identityPoolWithFederation(
                federatedToken: federatedToken,
                identityID: identityID,
                credentials: credentials
            )
        case .userPoolAndIdentityPool(let signedInData, let identityID, let credentials):
            self = .userPoolAndIdentityPool(
                signedInData: HostAppSignedInData(signedInData),
                identityID: identityID,
                credentials: credentials
            )
        case .noCredentials:
            self = .noCredentials
        }
    }
}

extension AmplifyCredentials {

    /// The engine value of host-app credentials, as written to `AWSCognitoAuthCredentialStore`.
    init(_ credentials: HostAppCredentials) {
        switch credentials {
        case .userPoolOnly(let signedInData):
            self = .userPoolOnly(signedInData: signedInData.signedInData)
        case .identityPoolOnly(let identityID, let credentials):
            self = .identityPoolOnly(identityID: identityID, credentials: credentials)
        case .identityPoolWithFederation(let federatedToken, let identityID, let credentials):
            self = .identityPoolWithFederation(
                federatedToken: federatedToken,
                identityID: identityID,
                credentials: credentials
            )
        case .userPoolAndIdentityPool(let signedInData, let identityID, let credentials):
            self = .userPoolAndIdentityPool(
                signedInData: signedInData.signedInData,
                identityID: identityID,
                credentials: credentials
            )
        case .noCredentials:
            self = .noCredentials
        }
    }
}

/// A `SignedInData`, with the members the host app reads.
struct HostAppSignedInData: Equatable {

    /// The engine value, unchanged.
    let signedInData: SignedInData

    init(_ signedInData: SignedInData) {
        self.signedInData = signedInData
    }

    /// `SignedInData(signedInDate:signInMethod:cognitoUserPoolTokens:)`.
    init(signedInDate: Date, signInMethod: SignInMethod, cognitoUserPoolTokens: EngineUserPoolTokens) {
        self.init(
            SignedInData(
                signedInDate: signedInDate,
                signInMethod: signInMethod,
                cognitoUserPoolTokens: cognitoUserPoolTokens
            )
        )
    }

    var signedInDate: Date {
        signedInData.signedInDate
    }

    var signInMethod: SignInMethod {
        signedInData.signInMethod
    }

    var cognitoUserPoolTokens: EngineUserPoolTokens {
        signedInData.cognitoUserPoolTokens
    }
}

extension SignInMethod {

    /// `.apiBased(_:)` for a public flow type, through the plugin's `EngineAuthFlowType(_:)` converter.
    init(apiBased flowType: AuthFlowType) {
        self = .apiBased(EngineAuthFlowType(flowType))
    }
}

/// Builds the engine's configuration values, and names their types, for the host app.
enum HostAppConfiguration {

    typealias Auth = AuthConfiguration
    typealias UserPool = UserPoolConfigurationData
    typealias IdentityPool = IdentityPoolConfigurationData

    /// `AuthConfiguration.userPools(_:)`.
    static func userPools(_ userPool: UserPool) -> Auth {
        .userPools(userPool)
    }

    /// `AuthConfiguration.identityPools(_:)`.
    static func identityPools(_ identityPool: IdentityPool) -> Auth {
        .identityPools(identityPool)
    }

    /// `AuthConfiguration.userPoolsAndIdentityPools(_:_:)`.
    static func userPoolsAndIdentityPools(_ userPool: UserPool, _ identityPool: IdentityPool) -> Auth {
        .userPoolsAndIdentityPools(userPool, identityPool)
    }

    /// `UserPoolConfigurationData(poolId:clientId:region:clientSecret:pinpointAppId:)`, every other
    /// member at the initializer's default.
    static func userPool(
        poolId: String,
        clientId: String,
        region: String,
        clientSecret: String? = nil,
        pinpointAppId: String? = nil
    ) -> UserPool {
        UserPoolConfigurationData(
            poolId: poolId,
            clientId: clientId,
            region: region,
            clientSecret: clientSecret,
            pinpointAppId: pinpointAppId
        )
    }

    /// `IdentityPoolConfigurationData(poolId:region:)`.
    static func identityPool(poolId: String, region: String) -> IdentityPool {
        IdentityPoolConfigurationData(poolId: poolId, region: region)
    }
}

/// `AWSCognitoAuthCredentialStore`, with the initializer and the two members the host app uses.
struct HostAppCredentialStore {

    /// The engine store, unchanged.
    let credentialStore: AWSCognitoAuthCredentialStore

    init(_ credentialStore: AWSCognitoAuthCredentialStore) {
        self.credentialStore = credentialStore
    }

    /// `AWSCognitoAuthCredentialStore(authConfiguration:accessGroup:migrateKeychainItemsOfUserSession:)`,
    /// with its defaults: the production keychain and `UserDefaults.standard`.
    init(
        authConfiguration: HostAppConfiguration.Auth,
        accessGroup: String? = nil,
        migrateKeychainItemsOfUserSession: Bool = false
    ) {
        self.init(
            AWSCognitoAuthCredentialStore(
                authConfiguration: authConfiguration,
                accessGroup: accessGroup,
                migrateKeychainItemsOfUserSession: migrateKeychainItemsOfUserSession,
                logger: AmplifyEngineLogRouter()
            )
        )
    }

    /// `AWSCognitoAuthCredentialStore.saveCredential(_:)`.
    func saveCredential(_ credential: AmplifyCredentials) throws {
        try credentialStore.saveCredential(credential)
    }

    /// `AWSCognitoAuthCredentialStore.retrieveCredential()`.
    func retrieveCredential() throws -> AmplifyCredentials {
        try credentialStore.retrieveCredential()
    }
}
