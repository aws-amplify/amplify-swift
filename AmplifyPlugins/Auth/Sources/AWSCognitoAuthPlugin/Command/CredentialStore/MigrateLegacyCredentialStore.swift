//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import hierarchical_state_machine_swift
import Amplify

struct MigrateLegacyCredentialStore: Command {

    let identifier = "MigrateLegacyCredentialStore"
    let authConfiguration: AuthConfiguration

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
    
    public func execute(withDispatcher dispatcher: EventDispatcher, environment: Environment) {
        
        let timer = LoggingTimer(identifier).start("### Starting execution")
        
        guard let credentialStoreEnvironment = (environment as? AuthEnvironment)?.credentialStoreEnvironment else {
            let event = CredentialStoreEvent(eventType: .loadCredentialStore(authConfiguration))
            timer.stop("### sending event \(event.type)")
            dispatcher.send(event)
            return
        }
        let amplifyCredentialStore = credentialStoreEnvironment.amplifyCredentialStoreFactory()

        var identityId: String?
        var awsCredentials: AuthAWSCognitoCredentials?
        
        let userPoolTokens = try? getUserPoolTokens(from: credentialStoreEnvironment)

        // IdentityId and AWSCredentials should exist together
        if let (storeIdentityId, storeAWSCredentials) = try? getIdentityIdAndAWSCredentials(from: credentialStoreEnvironment) {
            identityId = storeIdentityId
            awsCredentials = storeAWSCredentials
        }
        
        // If everything is nil, probably the store has been migrated
        if !(identityId == nil && awsCredentials == nil && userPoolTokens == nil) {
            let awsCognitoAuthCredentials = AWSCognitoAuthCredential(userPoolTokens: userPoolTokens,
                                                                     identityId: identityId,
                                                                     awsCredential: awsCredentials)
            
            // Save the fetched Credentials
            try? amplifyCredentialStore.saveCredential(awsCognitoAuthCredentials)
        }

        let event = CredentialStoreEvent(eventType: .loadCredentialStore(authConfiguration))
        timer.stop("### sending event \(event.type)")
        dispatcher.send(event)
    }
    
    private func getUserPoolTokens(from credentialStoreEnvironment: CredentialStoreEnvironment) throws -> AWSCognitoUserPoolTokens {
        
        guard let bundleIdentifier = Bundle.main.bundleIdentifier,
              let userPoolConfig = authConfiguration.getUserPoolConfiguration() else {
            throw AuthError.configuration(
                "Invalid Configuration when migrating legacy keychain",
                "Please check if the user pool configuration is correct and up to date.")
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
        from credentialStoreEnvironment: CredentialStoreEnvironment) throws -> (identityId: String, awsCredentials: AuthAWSCognitoCredentials) {
                        
            guard let bundleIdentifier = Bundle.main.bundleIdentifier,
                  let identityPoolConfig = authConfiguration.getIdentityPoolConfiguration() else {
                      throw AuthError.configuration(
                        "Invalid Configuration when migrating legacy keychain",
                        "Please check if the identity pool configuration is correct and up to date.")
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
    public var debugDictionary: [String: Any] {
        [
            "identifier": identifier,
            "configuration": authConfiguration
        ]
    }
}

extension MigrateLegacyCredentialStore: CustomDebugStringConvertible {
    public var debugDescription: String {
        debugDictionary.debugDescription
    }
}
