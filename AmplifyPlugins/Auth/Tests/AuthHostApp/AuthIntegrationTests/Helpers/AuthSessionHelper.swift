//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

@testable import Amplify
@testable import AWSCognitoAuthPlugin
import AWSPluginsCore
@_spi(KeychainStore) import AWSPluginsCore
import CryptoKit
import Foundation
import XCTest

struct AuthSessionHelper {

    static func getCurrentAmplifySession(
        shouldForceRefresh: Bool = false,
        for testCase: XCTestCase,
        with timeout: TimeInterval) async throws -> AWSAuthCognitoSession? {
            var cognitoSession: AWSAuthCognitoSession?
            let session = try await Amplify.Auth.fetchAuthSession(options: .init(forceRefresh: shouldForceRefresh))
            cognitoSession = (session as? AWSAuthCognitoSession)
            XCTAssertTrue(session.isSignedIn, "Session state should be signed In")
            return cognitoSession
        }

    static func clearSession() {
        let store = KeychainStore(service: "com.amplify.credentialStore")
        try? store._removeAll()
    }

    static func invalidateSession(with amplifyConfiguration: AmplifyConfiguration) {
        let configuration = getAuthConfiguration(configuration: amplifyConfiguration)
        let credentialStore = AWSCognitoAuthCredentialStore(authConfiguration: configuration, accessGroup: nil)
        guard let credentials = try? credentialStore.retrieveCredential() else {
            return
        }
        switch credentials {
        case .userPoolAndIdentityPool(signedInData: let signedInData,
                                      identityID: let identityID,
                                      credentials: let awsCredentials):
            let updatedToken = updateTokenWithPastExpiry(signedInData.cognitoUserPoolTokens)
            let signedInData = SignedInData(
                signedInDate: signedInData.signedInDate,
                signInMethod: signedInData.signInMethod,
                cognitoUserPoolTokens: updatedToken)
            let updatedCredentials = AmplifyCredentials.userPoolAndIdentityPool(
                signedInData: signedInData,
                identityID: identityID,
                credentials: awsCredentials)
            try! credentialStore.saveCredential(updatedCredentials)
        case  .userPoolOnly(signedInData: let signedInData):
            let updatedToken = updateTokenWithPastExpiry(signedInData.cognitoUserPoolTokens)
            let signedInData = SignedInData(
                signedInDate: signedInData.signedInDate,
                signInMethod: signedInData.signInMethod,
                cognitoUserPoolTokens: updatedToken)
            let updatedCredentials = AmplifyCredentials.userPoolOnly(signedInData: signedInData)
            try! credentialStore.saveCredential(updatedCredentials)
        default: break
        }

    }

    static private func updateTokenWithPastExpiry(_ tokens: AWSCognitoUserPoolTokens)
    -> AWSCognitoUserPoolTokens {
        var idToken = tokens.idToken
        var accessToken = tokens.accessToken
        if var idTokenClaims = try? AWSAuthService().getTokenClaims(tokenString: idToken).get(),
           var accessTokenClaims = try? AWSAuthService().getTokenClaims(tokenString: accessToken).get() {

            idTokenClaims["exp"] = String(Date(timeIntervalSinceNow: -3000).timeIntervalSince1970) as AnyObject
            accessTokenClaims["exp"] = String(Date(timeIntervalSinceNow: -3000).timeIntervalSince1970) as AnyObject
            idToken = CognitoAuthTestHelper.buildToken(for: idTokenClaims)
            accessToken = CognitoAuthTestHelper.buildToken(for: accessTokenClaims)
        }
        return AWSCognitoUserPoolTokens(idToken: idToken,
                                        accessToken: accessToken,
                                        refreshToken: "invalid",
                                        expiration: Date().addingTimeInterval(-50000))
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
                                          identityPoolConfig: IdentityPoolConfigurationData?) throws -> AuthConfiguration {

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

struct CognitoAuthTestHelper {

    /// Helper to build a JWT Token
    static func buildToken(for payload: [String: AnyObject]) -> String {

        struct Header: Encodable {
            let alg = "HS256"
            let typ = "JWT"
        }

        // target dict
        var dictionary = [String: String]()
        for (key, value) in payload {
            if let value = value as? String { dictionary[key] = value }
        }

        let secret = "256-bit-secret"
        let privateKey = SymmetricKey(data: Data(secret.utf8))

        let headerJSONData = try! JSONEncoder().encode(Header())
        let headerBase64String = headerJSONData.urlSafeBase64EncodedString()

        let payloadJSONData = try! JSONEncoder().encode(dictionary)
        let payloadBase64String = payloadJSONData.urlSafeBase64EncodedString()

        let toSign = Data((headerBase64String + "." + payloadBase64String).utf8)

        let signature = HMAC<SHA256>.authenticationCode(for: toSign, using: privateKey)
        let signatureBase64String = Data(signature).urlSafeBase64EncodedString()

        let token = [headerBase64String, payloadBase64String, signatureBase64String].joined(separator: ".")

        return token
    }
}

fileprivate extension Data {
    func urlSafeBase64EncodedString() -> String {
        return base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }
}
