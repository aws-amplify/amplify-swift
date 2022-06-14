//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import AWSPluginsCore
import Foundation

public struct AWSAuthCognitoSession: AuthSession,
                                     AuthAWSCredentialsProvider,
                                     AuthCognitoTokensProvider,
                                     AuthCognitoIdentityProvider {

    /// Indicates whether the user is signedIn or not
    public var isSignedIn: Bool

    public var userSubResult: Result<String, AuthError> {
        return getUserSub()
    }

    public let identityIdResult: Result<String, AuthError>

    public let awsCredentialsResult: Result<AuthAWSCredentials, AuthError>

    public let cognitoTokensResult: Result<AuthCognitoTokens, AuthError>

    init(isSignedIn: Bool,
         identityIdResult: Result<String, AuthError>,
         awsCredentialsResult: Result<AuthAWSCredentials, AuthError>,
         cognitoTokensResult: Result<AuthCognitoTokens, AuthError>) {
        self.isSignedIn = isSignedIn
        self.identityIdResult = identityIdResult
        self.awsCredentialsResult = awsCredentialsResult
        self.cognitoTokensResult = cognitoTokensResult
    }

    public func getAWSCredentials() -> Result<AuthAWSCredentials, AuthError> {
        return awsCredentialsResult
    }

    public func getCognitoTokens() -> Result<AuthCognitoTokens, AuthError> {
        return cognitoTokensResult
    }

    public func getIdentityId() -> Result<String, AuthError> {
        return identityIdResult
    }

    public func getUserSub() -> Result<String, AuthError> {
        do {
            let tokens = try cognitoTokensResult.get()
            let claims = try AWSAuthService().getTokenClaims(tokenString: tokens.idToken).get()
            guard let userSub = claims["sub"] as? String else {
                let error = AuthError.unknown("""
                                Could not retreive user sub from the fetched Cognito tokens.
                                """)
                return .failure(error)
            }
            return .success(userSub)
        } catch AuthError.signedOut {
            return .failure(AuthError.signedOut(
                            AuthPluginErrorConstants.userSubSignOutError.errorDescription,
                            AuthPluginErrorConstants.userSubSignOutError.recoverySuggestion))
        } catch let error as AuthError {
            return .failure(error)
        } catch {
            let error = AuthError.unknown("""
                            Could not retreive user sub from the fetched Cognito tokens.
                            """)
            return .failure(error)
        }
    }

}

/// Internal Helpers for managing session tokens
internal extension AWSAuthCognitoSession {
    func areTokensExpiring(in seconds: TimeInterval? = nil) -> Bool {

        guard let tokens = try? cognitoTokensResult.get(),
              let idTokenClaims = try? AWSAuthService().getTokenClaims(tokenString: tokens.idToken).get(),
              let accessTokenClaims = try? AWSAuthService().getTokenClaims(tokenString: tokens.idToken).get(),
              let idTokenExpiration = idTokenClaims["exp"]?.doubleValue,
              let accessTokenExpiration = accessTokenClaims["exp"]?.doubleValue else {
            return true
        }

        // If the session expires < X minutes return it
        return (Date(timeIntervalSince1970: idTokenExpiration).compare(Date(timeIntervalSinceNow: seconds ?? 0)) == .orderedDescending &&
                Date(timeIntervalSince1970: accessTokenExpiration).compare(Date(timeIntervalSinceNow: seconds ?? 0)) == .orderedDescending)
    }
}
