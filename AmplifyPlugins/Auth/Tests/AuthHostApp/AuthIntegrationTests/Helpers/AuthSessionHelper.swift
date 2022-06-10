//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

@testable import Amplify
@testable import AWSCognitoAuthPlugin
import Foundation

struct AuthSessionHelper {

    static func clearSession() {
        let store = CredentialStore(service: "com.amplify.credentialStore")
        try? store.removeAll()
    }
    
    static func invalidateSession(with amplifyConfiguration: AmplifyConfiguration) {
        let configuration = getAuthConfiguration(configuration: amplifyConfiguration)
        let credentialStore = AWSCognitoAuthCredentialStore(authConfiguration: configuration, accessGroup: nil)
        let credentials = try! credentialStore.retrieveCredential()
        
        if let tokens = credentials.userPoolTokens {
            let updatedCredentials = CognitoCredentials(
                userPoolTokens: AWSCognitoUserPoolTokens(idToken: tokens.idToken,
                                                         accessToken: tokens.accessToken,
                                                         refreshToken: "invalid",
                                                         expiration: Date().addingTimeInterval(-50000)),
                identityId: credentials.identityId,
                awsCredential: credentials.awsCredential)
            try! credentialStore.saveCredential(updatedCredentials)
        }
    }
    
    static private func getAuthConfiguration(configuration: AmplifyConfiguration) -> AuthConfiguration {
        let jsonValueConfiguration = configuration.auth!.plugins["awsCognitoAuthPlugin"]!
        let userPoolConfigData = parseUserPoolConfigData(jsonValueConfiguration)
        let identityPoolConfigData = parseIdentityPoolConfigData(jsonValueConfiguration)
        return try! authConfiguration(userPoolConfig: userPoolConfigData,
                                      identityPoolConfig: identityPoolConfigData)
    }
    
    
    static private func parseUserPoolConfigData(_ config: JSONValue) -> UserPoolConfigurationData? {
        // TODO: Use JSON serialization here to convert.
        guard let cognitoUserPoolJSON = config.value(at: "CognitoUserPool.Default") else {
            Amplify.Logging.info("Could not find Cognito User Pool configuration")
            return nil
        }
        guard case .string(let poolId)  = cognitoUserPoolJSON.value(at: "PoolId"),
              case .string(let appClientId) = cognitoUserPoolJSON.value(at: "AppClientId"),
              case .string(let region) = cognitoUserPoolJSON.value(at: "Region")
        else {
            return nil
        }

        var clientSecret: String?
        if case .string(let clientSecretFromConfig) = cognitoUserPoolJSON.value(at: "AppClientSecret") {
            clientSecret = clientSecretFromConfig
        }
        return UserPoolConfigurationData(poolId: poolId,
                                         clientId: appClientId,
                                         region: region,
                                         clientSecret: clientSecret)
    }

    static private func parseIdentityPoolConfigData(_ config: JSONValue) -> IdentityPoolConfigurationData? {

        guard let cognitoIdentityPoolJSON = config.value(at: "CredentialsProvider.CognitoIdentity.Default") else {
            Amplify.Logging.info("Could not find Cognito Identity Pool configuration")
            return nil
        }
        guard case .string(let poolId) = cognitoIdentityPoolJSON.value(at: "PoolId"),
              case .string(let region) = cognitoIdentityPoolJSON.value(at: "Region")
        else {
            return nil
        }
        return IdentityPoolConfigurationData(poolId: poolId, region: region)
    }
    
    static private func authConfiguration(userPoolConfig: UserPoolConfigurationData?,
                           identityPoolConfig: IdentityPoolConfigurationData?) throws -> AuthConfiguration
    {

        if let userPoolConfigNonNil = userPoolConfig, let identityPoolConfigNonNil = identityPoolConfig {
            return .userPoolsAndIdentityPools(userPoolConfigNonNil, identityPoolConfigNonNil)
        }
        if  let userPoolConfigNonNil = userPoolConfig {
            return .userPools(userPoolConfigNonNil)
        }
        if  let identityPoolConfigNonNil = identityPoolConfig {
            return .identityPools(identityPoolConfigNonNil)
        }
        // Could not get either Userpool or Identitypool configuration
        // Throw an error to stop the configure flow.
        throw AuthError.configuration(
            "Error configuring \(String(describing: self))",
            AuthPluginErrorConstants.configurationMissingError
        )
    }
}
