//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

import Amplify

struct MigrateLegacyCredentialStore: Action {

    let identifier = "MigrateLegacyCredentialStore"

    /// Legacy Keys
    private let cognitoAWSCredentialsProviderClassKey = "AWSCognitoCredentialsProvider"
    private let cognitoUserPoolClassKey = "AWSCognitoIdentityUserPool"
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

        let timer = LoggingTimer(identifier).start("### Starting execution")

        guard let credentialEnvironment = environment as? CredentialEnvironment else {
            let event = CredentialStoreEvent(
                eventType: .throwError(CredentialStoreError.configuration(
                    message: AuthPluginErrorConstants.configurationError)))
            timer.stop("### sending event \(event.type)")
            dispatcher.send(event)
            return
        }
        let credentialStoreEnvironment = credentialEnvironment.credentialStoreEnvironment
        let authConfiguration = credentialEnvironment.authConfiguration

        let amplifyCredentialStore = credentialStoreEnvironment.amplifyCredentialStoreFactory()

        var identityId: String?
        var awsCredentials: AuthAWSCognitoCredentials?

        let userPoolTokens = try? getUserPoolTokens(from: credentialStoreEnvironment, with: authConfiguration)

        // IdentityId and AWSCredentials should exist together
        if let (storedIdentityId, storedAWSCredentials) = try? getIdentityIdAndAWSCredentials(from: credentialStoreEnvironment,
                                                                                            with: authConfiguration)
        {
            identityId = storedIdentityId
            awsCredentials = storedAWSCredentials
        }

        do {
            // If everything is nil, probably the store has been migrated
            if !(identityId == nil && awsCredentials == nil && userPoolTokens == nil) {
                let credentials = CognitoCredentials(userPoolTokens: userPoolTokens,
                                                     identityId: identityId,
                                                     awsCredential: awsCredentials)

                // Save the fetched Credentials
                try amplifyCredentialStore.saveCredential(credentials)
            }
            let event = CredentialStoreEvent(eventType: .loadCredentialStore)
            timer.stop("### sending event \(event.type)")
            dispatcher.send(event)
        } catch let error as CredentialStoreError {
            let event = CredentialStoreEvent(eventType: .throwError(error))
            timer.stop("### sending event \(event.type)")
            dispatcher.send(event)
        } catch {
            let event = CredentialStoreEvent(
                eventType: .throwError(CredentialStoreError.unknown("An unknown error occurred", error)))
            timer.stop("### sending event \(event.type)")
            dispatcher.send(event)
        }

    }

    private func getUserPoolTokens(from credentialStoreEnvironment: CredentialStoreEnvironment,
                                   with authConfiguration: AuthConfiguration) throws -> AWSCognitoUserPoolTokens
    {

        guard let bundleIdentifier = Bundle.main.bundleIdentifier,
              let userPoolConfig = authConfiguration.getUserPoolConfiguration()
        else {
            throw CredentialStoreError.configuration(
                message: AuthPluginErrorConstants.configurationError)
        }

        let serviceKey = "\(bundleIdentifier).\(cognitoUserPoolClassKey)"
        let legacyCredentialStore = credentialStoreEnvironment.legacyCredentialStoreFactory(serviceKey)
        defer {
            // Clean up the old store
            try? legacyCredentialStore.removeAll()
        }
        let currentUser = try legacyCredentialStore.getString(
            userPoolNamespace(
                userPoolConfig: userPoolConfig,
                for: AWSCognitoAuthUserPoolCurrentUser
            )
        )
        let idToken = try legacyCredentialStore.getString(
            userPoolNamespace(
                userPoolConfig: userPoolConfig,
                for: "\(currentUser).\(AWSCognitoAuthUserIdToken)"
            )
        )
        let accessToken = try legacyCredentialStore.getString(
            userPoolNamespace(
                userPoolConfig: userPoolConfig,
                for: "\(currentUser).\(AWSCognitoAuthUserAccessToken)"
            )
        )
        let refreshToken = try legacyCredentialStore.getString(
            userPoolNamespace(
                userPoolConfig: userPoolConfig,
                for: "\(currentUser).\(AWSCognitoAuthUserRefreshToken)"
            )
        )
        let tokenExpirationString = try legacyCredentialStore.getString(
            userPoolNamespace(
                userPoolConfig: userPoolConfig,
                for: "\(currentUser).\(AWSCognitoAuthUserTokenExpiration)"
            )
        )
        // If the token expiration can't be converted to a date, chose a date in the past
        let tokenExpiration = dateFormatter().date(from: tokenExpirationString) ?? Date.init(timeIntervalSince1970: 0)
        return AWSCognitoUserPoolTokens(idToken: idToken,
                                        accessToken: accessToken,
                                        refreshToken: refreshToken,
                                        expiration: tokenExpiration)
    }

    private func userPoolNamespace(userPoolConfig: UserPoolConfigurationData, for key: String) -> String {
        return "\(userPoolConfig.clientId).\(key)"
    }

    private func getIdentityIdAndAWSCredentials(
        from credentialStoreEnvironment: CredentialStoreEnvironment,
        with authConfiguration: AuthConfiguration) throws -> (identityId: String, awsCredentials: AuthAWSCognitoCredentials)
    {

        guard let bundleIdentifier = Bundle.main.bundleIdentifier,
              let identityPoolConfig = authConfiguration.getIdentityPoolConfiguration()
        else {
            throw CredentialStoreError.configuration(
                message: AuthPluginErrorConstants.configurationError)
        }

        let serviceKey = "\(bundleIdentifier).\(cognitoAWSCredentialsProviderClassKey).\(identityPoolConfig.poolId)"
        let legacyCredentialStore = credentialStoreEnvironment.legacyCredentialStoreFactory(serviceKey)
        defer {
            // Clean up the old store
            try? legacyCredentialStore.removeAll()
        }
        let accessKey = try legacyCredentialStore.getString(AWSCredentialsProviderKeychainAccessKeyId)
        let secretKey = try legacyCredentialStore.getString(AWSCredentialsProviderKeychainSecretAccessKey)
        let sessionKey = try legacyCredentialStore.getString(AWSCredentialsProviderKeychainSessionToken)
        let expirationString = try legacyCredentialStore.getString(AWSCredentialsProviderKeychainExpiration)
        let identityId = try legacyCredentialStore.getString(AWSCredentialsProviderKeychainIdentityId)

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
