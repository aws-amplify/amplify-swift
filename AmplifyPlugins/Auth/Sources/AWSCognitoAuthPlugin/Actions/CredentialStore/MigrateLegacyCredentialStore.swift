//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify
@_spi(KeychainStore) import AWSPluginsCore

struct MigrateLegacyCredentialStore: Action {

    let identifier = "MigrateLegacyCredentialStore"

    /// Legacy Keys
    private let AWSCredentialsProviderClassKey = "AWSCognitoCredentialsProvider"
    private let UserPoolClassKey = "AWSCognitoIdentityUserPool"
    private let AWSCredentialsProviderKeychainAccessKeyId = "accessKey"
    private let AWSCredentialsProviderKeychainSecretAccessKey = "secretKey"
    private let AWSCredentialsProviderKeychainSessionToken = "sessionKey"
    private let AWSCredentialsProviderKeychainExpiration = "expiration"
    private let AWSCredentialsProviderKeychainIdentityId = "identityId"

    private let AWSCognitoAuthUserPoolCurrentUser = "currentUser"
    private let AWSCognitoAuthUserAccessToken = "accessToken"
    private let AWSCognitoAuthUserIdToken = "idToken"
    private let AWSCognitoAuthUserRefreshToken = "refreshToken"
    private let AWSCognitoAuthUserTokenExpiration = "tokenExpiration"

    func execute(withDispatcher dispatcher: EventDispatcher, environment: Environment) {

        logVerbose("\(#fileID) Starting execution", environment: environment)

        guard let credentialEnvironment = environment as? CredentialEnvironment else {
            let event = CredentialStoreEvent(
                eventType: .throwError(KeychainStoreError.configuration(
                    message: AuthPluginErrorConstants.configurationError)))
            logVerbose("\(#fileID) Sending event \(event.type)", environment: environment)
            dispatcher.send(event)
            return
        }

        let credentialStoreEnvironment = credentialEnvironment.credentialStoreEnvironment
        let authConfiguration = credentialEnvironment.authConfiguration

        let amplifyCredentialStore = credentialStoreEnvironment.amplifyCredentialStoreFactory()

        var identityId: String?
        var awsCredentials: AuthAWSCognitoCredentials?

        let userPoolTokens = try? getUserPoolTokens(from: credentialStoreEnvironment,
                                                    with: authConfiguration)

        // IdentityId and AWSCredentials should exist together
        if let (storedIdentityId,
                storedAWSCredentials) = try? getIdentityIdAndAWSCredentials(
                    from: credentialStoreEnvironment,
                    with: authConfiguration) {
            identityId = storedIdentityId
            awsCredentials = storedAWSCredentials
        }

        do {
            if let identityId = identityId,
               let awsCredentials = awsCredentials,
               userPoolTokens == nil {
                let credentials = AmplifyCredentials.identityPoolOnly(
                    identityID: identityId,
                    credentials: awsCredentials)
                try amplifyCredentialStore.saveCredential(credentials)

            } else if let identityId = identityId,
               let awsCredentials = awsCredentials,
               let userPoolTokens = userPoolTokens {
                let credentials = AmplifyCredentials.userPoolAndIdentityPool(
                    tokens: userPoolTokens,
                    identityID: identityId,
                    credentials: awsCredentials)
                try amplifyCredentialStore.saveCredential(credentials)

            } else if let userPoolTokens = userPoolTokens {
                let credentials = AmplifyCredentials.userPoolOnly(tokens: userPoolTokens)
                try amplifyCredentialStore.saveCredential(credentials)
            }

            let event = CredentialStoreEvent(eventType: .loadCredentialStore)
            logVerbose("\(#fileID) Sending event \(event.type)", environment: environment)
            dispatcher.send(event)
        } catch let error as KeychainStoreError {
            let event = CredentialStoreEvent(eventType: .throwError(error))
            logVerbose("\(#fileID) Sending event \(event.type)", environment: environment)
            dispatcher.send(event)
        } catch {
            let event = CredentialStoreEvent(
                eventType: .throwError(
                    KeychainStoreError.unknown("An unknown error occurred", error)))
            logVerbose("\(#fileID) Sending event \(event.type)", environment: environment)
            dispatcher.send(event)
        }
    }

    private func getUserPoolTokens(
        from credentialStoreEnvironment: CredentialStoreEnvironment,
        with authConfiguration: AuthConfiguration) throws -> AWSCognitoUserPoolTokens {

            guard let bundleIdentifier = Bundle.main.bundleIdentifier,
                  let userPoolConfig = authConfiguration.getUserPoolConfiguration()
            else {
                throw KeychainStoreError.configuration(
                    message: AuthPluginErrorConstants.configurationError)
            }

            let serviceKey = "\(bundleIdentifier).\(UserPoolClassKey)"
            let legacyKeychainStore = credentialStoreEnvironment.legacyKeychainStoreFactory(serviceKey)
            defer {
                // Clean up the old store
                try? legacyKeychainStore._removeAll()
            }
            let currentUser = try legacyKeychainStore._getString(
                userPoolNamespace(
                    userPoolConfig: userPoolConfig,
                    for: AWSCognitoAuthUserPoolCurrentUser
                )
            )
            let idToken = try legacyKeychainStore._getString(
                userPoolNamespace(
                    userPoolConfig: userPoolConfig,
                    for: "\(currentUser).\(AWSCognitoAuthUserIdToken)"
                )
            )
            let accessToken = try legacyKeychainStore._getString(
                userPoolNamespace(
                    userPoolConfig: userPoolConfig,
                    for: "\(currentUser).\(AWSCognitoAuthUserAccessToken)"
                )
            )
            let refreshToken = try legacyKeychainStore._getString(
                userPoolNamespace(
                    userPoolConfig: userPoolConfig,
                    for: "\(currentUser).\(AWSCognitoAuthUserRefreshToken)"
                )
            )
            let tokenExpirationString = try legacyKeychainStore._getString(
                userPoolNamespace(
                    userPoolConfig: userPoolConfig,
                    for: "\(currentUser).\(AWSCognitoAuthUserTokenExpiration)"
                )
            )
            // If the token expiration can't be converted to a date, chose a date in the past
            let pastDate = Date.init(timeIntervalSince1970: 0)
            let tokenExpiration = dateFormatter().date(from: tokenExpirationString) ?? pastDate
            return AWSCognitoUserPoolTokens(idToken: idToken,
                                            accessToken: accessToken,
                                            refreshToken: refreshToken,
                                            expiration: tokenExpiration)
        }

    private func userPoolNamespace(userPoolConfig: UserPoolConfigurationData,
                                   for key: String) -> String {
        return "\(userPoolConfig.clientId).\(key)"
    }

    private func getIdentityIdAndAWSCredentials(
        from credentialStoreEnvironment: CredentialStoreEnvironment,
        with authConfiguration: AuthConfiguration) throws
    -> (identityId: String, awsCredentials: AuthAWSCognitoCredentials) {

        guard let bundleIdentifier = Bundle.main.bundleIdentifier,
              let identityPoolConfig = authConfiguration.getIdentityPoolConfiguration()
        else {
            throw KeychainStoreError.configuration(
                message: AuthPluginErrorConstants.configurationError)
        }

        let poolId = identityPoolConfig.poolId
        let serviceKey = "\(bundleIdentifier).\(AWSCredentialsProviderClassKey).\(poolId)"
        let legacyKeychainStore = credentialStoreEnvironment.legacyKeychainStoreFactory(serviceKey)
        defer {
            // Clean up the old store
            try? legacyKeychainStore._removeAll()
        }
        let accessKey = try legacyKeychainStore._getString(
            AWSCredentialsProviderKeychainAccessKeyId)
        let secretKey = try legacyKeychainStore._getString(
            AWSCredentialsProviderKeychainSecretAccessKey)
        let sessionKey = try legacyKeychainStore._getString(
            AWSCredentialsProviderKeychainSessionToken)
        let expirationString = try legacyKeychainStore._getString(
            AWSCredentialsProviderKeychainExpiration)
        let identityId = try legacyKeychainStore._getString(
            AWSCredentialsProviderKeychainIdentityId)

        let awsCredentials = AuthAWSCognitoCredentials(
            accessKey: accessKey,
            secretKey: secretKey,
            sessionKey: sessionKey,
            expiration: Date(timeIntervalSince1970: Double(expirationString) ?? 0)
        )
        return (identityId, awsCredentials)
    }

    private func dateFormatter() -> DateFormatter {
        let dateFormatter = DateFormatter()
        dateFormatter.timeZone = TimeZone.utc
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'Z'"
        return dateFormatter
    }
}

extension MigrateLegacyCredentialStore: DefaultLogger { }

extension MigrateLegacyCredentialStore: CustomDebugDictionaryConvertible {
    var debugDictionary: [String: Any] {
        [
            "identifier": identifier
        ]
    }
}

extension MigrateLegacyCredentialStore: CustomDebugStringConvertible {
    var debugDescription: String {
        debugDictionary.debugDescription
    }
}
