//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import AWSPluginsCore

public struct AWSAuthCognitoSession: AuthSession,
                                     AuthAWSCredentialsProvider,
                                     AuthCognitoTokensProvider,
                                     AuthCognitoIdentityProvider {

    /// Indicates whether the user is signedIn or not
    public var isSignedIn: Bool

    public let userSubResult: Result<String, AuthError>

    public let identityIdResult: Result<String, AuthError>

    public let awsCredentialsResult: Result<AuthAWSCredentials, AuthError>

    public let cognitoTokensResult: Result<AuthCognitoTokens, AuthError>

    init(isSignedIn: Bool,
         userSubResult: Result<String, AuthError>,
         identityIdResult: Result<String, AuthError>,
         awsCredentialsResult: Result<AuthAWSCredentials, AuthError>,
         cognitoTokensResult: Result<AuthCognitoTokens, AuthError>) {
        self.isSignedIn = isSignedIn
        self.userSubResult = userSubResult
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
        return userSubResult
    }
}

/// Helper method to update specific results if needed
extension AWSAuthCognitoSession {

    func getCognitoCredentials() -> CognitoCredentials {
        var identityId: String?
        if case let .success(unwrappedIdentityId) = getIdentityId() {
            identityId = unwrappedIdentityId
        }

        var cognitUserPoolTokens: AWSCognitoUserPoolTokens?
        if case let .success(tokens) = getCognitoTokens(),
           let unwrappedTokens = tokens as? AWSCognitoUserPoolTokens {
            cognitUserPoolTokens = unwrappedTokens
        }

        var awsCredentials: AuthAWSCognitoCredentials?
        if case let .success(credentials) = getAWSCredentials(),
            let unwrappedCredentials = credentials as? AuthAWSCognitoCredentials {
            awsCredentials = unwrappedCredentials
        }

        return CognitoCredentials(userPoolTokens: cognitUserPoolTokens,
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
        let userSubResultCopy: Result<String, AuthError>

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

        if let unwrappedUserSubResultCopy = userSubResult {
            userSubResultCopy = unwrappedUserSubResultCopy
        } else {
            userSubResultCopy = self.userSubResult
        }

        return AWSAuthCognitoSession(
            isSignedIn: isSignedInCopy,
            userSubResult: userSubResultCopy,
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
