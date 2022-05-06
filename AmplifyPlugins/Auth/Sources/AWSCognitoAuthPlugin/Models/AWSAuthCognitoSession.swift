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
                                     AuthCognitoIdentityProvider
{

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
         cognitoTokensResult: Result<AuthCognitoTokens, AuthError>)
    {
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
        } catch let error as AuthError{
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

/// Helper method to update specific results if needed
extension AWSAuthCognitoSession {

    func getCognitoCredentials() -> AmplifyCredentials {
        var identityId: String?
        if case let .success(unwrappedIdentityId) = getIdentityId() {
            identityId = unwrappedIdentityId
        }

        var cognitUserPoolTokens: AWSCognitoUserPoolTokens?
        if case let .success(tokens) = getCognitoTokens(),
           let unwrappedTokens = tokens as? AWSCognitoUserPoolTokens
        {
            cognitUserPoolTokens = unwrappedTokens
        }

        var awsCredentials: AuthAWSCognitoCredentials?
        if case let .success(credentials) = getAWSCredentials(),
           let unwrappedCredentials = credentials as? AuthAWSCognitoCredentials
        {
            awsCredentials = unwrappedCredentials
        }

        return AmplifyCredentials(userPoolTokens: cognitUserPoolTokens,
                                  identityId: identityId,
                                  awsCredential: awsCredentials)
    }

    func copySessionByUpdating(
        isSignedIn: Bool? = nil,
        userSubResult: Result<String, AuthError>? = nil,
        identityIdResult: Result<String, AuthError>? = nil,
        awsCredentialsResult: Result<AuthAWSCredentials, AuthError>? = nil,
        cognitoTokensResult: Result<AuthCognitoTokens, AuthError>? = nil
    ) -> AWSAuthCognitoSession {

        let isSignedInCopy: Bool
        let identityIdResultCopy: Result<String, AuthError>
        let awsCredentialsResultCopy: Result<AuthAWSCredentials, AuthError>
        let cognitoTokensResultCopy: Result<AuthCognitoTokens, AuthError>

        if let unwrappedIsSignedIn = isSignedIn {
            isSignedInCopy = unwrappedIsSignedIn
        } else {
            isSignedInCopy = self.isSignedIn
        }

        if let unwrappedIdentityIdResult = identityIdResult {
            identityIdResultCopy = unwrappedIdentityIdResult
        } else {
            identityIdResultCopy = self.identityIdResult
        }

        if let unwrappedAWSCredentialResult = awsCredentialsResult {
            awsCredentialsResultCopy = unwrappedAWSCredentialResult
        } else {
            awsCredentialsResultCopy = self.awsCredentialsResult
        }

        if let unwrappedCognitoTokensResult = cognitoTokensResult {
            cognitoTokensResultCopy = unwrappedCognitoTokensResult
        } else {
            cognitoTokensResultCopy = self.cognitoTokensResult
        }

        return AWSAuthCognitoSession(
            isSignedIn: isSignedInCopy,
            identityIdResult: identityIdResultCopy,
            awsCredentialsResult: awsCredentialsResultCopy,
            cognitoTokensResult: cognitoTokensResultCopy
        )
    }

}

extension AWSAuthCognitoSession: Equatable {
    public static func == (lhs: AWSAuthCognitoSession, rhs: AWSAuthCognitoSession) -> Bool {

        let isSignedInEqual = lhs.isSignedIn == rhs.isSignedIn
        let isUserSubResultEqual: Bool
        let identityResultEqual: Bool
        let awsCredentialResultEqual: Bool
        let cognitoTokensResultEqual: Bool

        switch (lhs.userSubResult, rhs.userSubResult) {
        case (.failure, .failure):
            isUserSubResultEqual = true
        case (.success(let lhsString), .success(let rhsString)):
            isUserSubResultEqual = (lhsString == rhsString)
        default:
            isUserSubResultEqual = false
        }

        switch (lhs.identityIdResult, rhs.identityIdResult) {
        case (.failure, .failure):
            identityResultEqual = true
        case (.success(let lhsIdentityId), .success(let rhsIdentityId)):
            identityResultEqual = (lhsIdentityId == rhsIdentityId)
        default:
            identityResultEqual = false
        }

        switch (lhs.awsCredentialsResult, rhs.awsCredentialsResult) {
        case (.failure, .failure):
            awsCredentialResultEqual = true
        case (.success(let lhsAWSCredentials), .success(let rhsAWSCredentials)):
            awsCredentialResultEqual = (lhsAWSCredentials.secretKey == rhsAWSCredentials.secretKey &&
                                        lhsAWSCredentials.accessKey == rhsAWSCredentials.accessKey)
        default:
            awsCredentialResultEqual = false
        }

        switch (lhs.cognitoTokensResult, rhs.cognitoTokensResult) {
        case (.failure, .failure):
            cognitoTokensResultEqual = true
        case (.success(let lhsCognitoResult), .success(let rhsCognitoResult)):
            cognitoTokensResultEqual = (lhsCognitoResult.accessToken == rhsCognitoResult.accessToken &&
                                        lhsCognitoResult.idToken == rhsCognitoResult.idToken &&
                                        lhsCognitoResult.refreshToken == rhsCognitoResult.refreshToken)
        default:
            cognitoTokensResultEqual = false
        }

        return isSignedInEqual && isUserSubResultEqual && identityResultEqual && awsCredentialResultEqual && cognitoTokensResultEqual
    }
}
