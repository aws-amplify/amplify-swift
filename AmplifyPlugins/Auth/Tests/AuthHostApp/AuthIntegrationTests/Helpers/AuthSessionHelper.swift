//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AWSPluginsCore
@testable import Amplify
@testable import AWSCognitoAuthPlugin
@_spi(KeychainStore) import AWSPluginsCore
import CryptoKit
import Foundation
import XCTest

struct AuthSessionHelper {

    static func getCurrentAmplifySession(
        shouldForceRefresh: Bool = false,
        for testCase: XCTestCase,
        with timeout: TimeInterval
    ) async throws -> AWSAuthCognitoSession? {
            var cognitoSession: AWSAuthCognitoSession?
            let session = try await Amplify.Auth.fetchAuthSession(options: .init(forceRefresh: shouldForceRefresh))
            cognitoSession = (session as? AWSAuthCognitoSession)
            XCTAssertTrue(session.isSignedIn, "Session state should be signed In")
            return cognitoSession
        }

    static func clearSession() {
        let store = KeychainStore(service: "com.amplify.awsCognitoAuthPlugin")
        try? store._removeAll()
    }

    static func invalidateSession(with amplifyConfiguration: AmplifyConfiguration) {
        invalidateSession(authConfiguration: getAuthConfiguration(configuration: amplifyConfiguration))
    }

    /// As `invalidateSession(with:)`, for a Gen2 `amplify_outputs` file.
    static func invalidateSession(withOutputs data: Data) throws {
        let outputs = try JSONDecoder().decode(JSONValue.self, from: data)
        guard case .string(let region) = outputs.value(at: "auth.aws_region"),
              case .string(let poolId) = outputs.value(at: "auth.user_pool_id"),
              case .string(let clientId) = outputs.value(at: "auth.user_pool_client_id")
        else {
            throw AuthError.configuration("The amplify_outputs file has no user pool", "", nil)
        }
        let userPool = HostAppConfiguration.userPool(poolId: poolId, clientId: clientId, region: region, clientSecret: nil)
        var identityPool: HostAppConfiguration.IdentityPool?
        if case .string(let identityPoolId) = outputs.value(at: "auth.identity_pool_id") {
            identityPool = HostAppConfiguration.identityPool(poolId: identityPoolId, region: region)
        }
        try invalidateSession(authConfiguration: authConfiguration(userPoolConfig: userPool, identityPoolConfig: identityPool))
    }

    private static func invalidateSession(authConfiguration configuration: HostAppConfiguration.Auth) {
        let credentialStore = HostAppCredentialStore(authConfiguration: configuration, accessGroup: nil)
        guard let credentials = try? HostAppCredentials(credentialStore.retrieveCredential()) else {
            return
        }
        switch credentials {
        case .userPoolAndIdentityPool(
            signedInData: let signedInData,
            identityID: let identityID,
            credentials: let awsCredentials
        ):
            let updatedToken = updateTokenWithPastExpiry(.init(signedInData.cognitoUserPoolTokens))
            let signedInData = HostAppSignedInData(
                signedInDate: signedInData.signedInDate,
                signInMethod: signedInData.signInMethod,
                cognitoUserPoolTokens: .init(updatedToken)
            )
            let updatedCredentials = HostAppCredentials.userPoolAndIdentityPool(
                signedInData: signedInData,
                identityID: identityID,
                credentials: awsCredentials
            )
            try! credentialStore.saveCredential(.init(updatedCredentials))
        case  .userPoolOnly(signedInData: let signedInData):
            let updatedToken = updateTokenWithPastExpiry(.init(signedInData.cognitoUserPoolTokens))
            let signedInData = HostAppSignedInData(
                signedInDate: signedInData.signedInDate,
                signInMethod: signedInData.signInMethod,
                cognitoUserPoolTokens: .init(updatedToken)
            )
            let updatedCredentials = HostAppCredentials.userPoolOnly(signedInData: signedInData)
            try! credentialStore.saveCredential(.init(updatedCredentials))
        default: break
        }

    }

    private static func updateTokenWithPastExpiry(_ tokens: AWSCognitoUserPoolTokens)
    -> AWSCognitoUserPoolTokens {
        var idToken = tokens.idToken
        var accessToken = tokens.accessToken
        if var idTokenClaims = try? AWSAuthService().getTokenClaims(tokenString: idToken).get(),
           var accessTokenClaims = try? AWSAuthService().getTokenClaims(tokenString: accessToken).get() {

            idTokenClaims["exp"] = String(Date(timeIntervalSinceNow: -3_000).timeIntervalSince1970) as AnyObject
            accessTokenClaims["exp"] = String(Date(timeIntervalSinceNow: -3_000).timeIntervalSince1970) as AnyObject
            idToken = CognitoAuthTestHelper.buildToken(for: idTokenClaims)
            accessToken = CognitoAuthTestHelper.buildToken(for: accessTokenClaims)
        }
        return AWSCognitoUserPoolTokens(
            idToken: idToken,
            accessToken: accessToken,
            refreshToken: "invalid",
            expiration: Date().addingTimeInterval(-50_000)
        )
    }

    private static func getAuthConfiguration(configuration: AmplifyConfiguration) -> HostAppConfiguration.Auth {
        let jsonValueConfiguration = configuration.auth!.plugins["awsCognitoAuthPlugin"]!
        let userPoolConfigData = parseUserPoolConfigData(jsonValueConfiguration)
        let identityPoolConfigData = parseIdentityPoolConfigData(jsonValueConfiguration)
        return try! authConfiguration(
            userPoolConfig: userPoolConfigData,
            identityPoolConfig: identityPoolConfigData
        )
    }

    private static func parseUserPoolConfigData(_ config: JSONValue) -> HostAppConfiguration.UserPool? {
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
        return HostAppConfiguration.userPool(
            poolId: poolId,
            clientId: appClientId,
            region: region,
            clientSecret: clientSecret
        )
    }

    private static func parseIdentityPoolConfigData(_ config: JSONValue) -> HostAppConfiguration.IdentityPool? {

        guard let cognitoIdentityPoolJSON = config.value(at: "CredentialsProvider.CognitoIdentity.Default") else {
            Amplify.Logging.info("Could not find Cognito Identity Pool configuration")
            return nil
        }
        guard case .string(let poolId) = cognitoIdentityPoolJSON.value(at: "PoolId"),
              case .string(let region) = cognitoIdentityPoolJSON.value(at: "Region")
        else {
            return nil
        }
        return HostAppConfiguration.identityPool(poolId: poolId, region: region)
    }

    private static func authConfiguration(
        userPoolConfig: HostAppConfiguration.UserPool?,
        identityPoolConfig: HostAppConfiguration.IdentityPool?
    ) throws -> HostAppConfiguration.Auth {

        if let userPoolConfigNonNil = userPoolConfig, let identityPoolConfigNonNil = identityPoolConfig {
            return HostAppConfiguration.userPoolsAndIdentityPools(userPoolConfigNonNil, identityPoolConfigNonNil)
        }
        if  let userPoolConfigNonNil = userPoolConfig {
            return HostAppConfiguration.userPools(userPoolConfigNonNil)
        }
        if  let identityPoolConfigNonNil = identityPoolConfig {
            return HostAppConfiguration.identityPools(identityPoolConfigNonNil)
        }
        // Could not get either Userpool or Identitypool configuration
        // Throw an error to stop the configure flow.
        throw AuthError.configuration(
            "Error configuring \(String(describing: self))",
            // `AuthPluginErrorConstants` is a package type of the engine, which this Xcode target
            // (outside the SwiftPM package) cannot see.
            "Could not read Cognito Service configuration from the auth configuration."
        )
    }
}

enum CognitoAuthTestHelper {

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

private extension Data {
    func urlSafeBase64EncodedString() -> String {
        return base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }
}
