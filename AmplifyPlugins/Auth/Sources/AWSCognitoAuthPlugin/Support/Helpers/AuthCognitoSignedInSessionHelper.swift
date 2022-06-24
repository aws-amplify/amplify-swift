//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify

struct AuthCognitoSignedInSessionHelper {

    static func makeOfflineSignedInSession() -> AWSAuthCognitoSession {
        let identityIdError = AuthError.service(
            AuthPluginErrorConstants.identityIdOfflineError.errorDescription,
            AuthPluginErrorConstants.identityIdOfflineError.recoverySuggestion,
            AWSCognitoAuthError.network)

        let awsCredentialsError = AuthError.service(
            AuthPluginErrorConstants.awsCredentialsOfflineError.errorDescription,
            AuthPluginErrorConstants.awsCredentialsOfflineError.recoverySuggestion,
            AWSCognitoAuthError.network)

        let tokensError = AuthError.service(
            AuthPluginErrorConstants.cognitoTokenOfflineError.errorDescription,
            AuthPluginErrorConstants.cognitoTokenOfflineError.recoverySuggestion,
            AWSCognitoAuthError.network)

        let authSession = AWSAuthCognitoSession(isSignedIn: true,
                                                identityIdResult: .failure(identityIdError),
                                                awsCredentialsResult: .failure(awsCredentialsError),
                                                cognitoTokensResult: .failure(tokensError))
        return authSession
    }

    static func makeExpiredSignedInSession() -> AWSAuthCognitoSession {
        let identityIdError = AuthError.sessionExpired(
            AuthPluginErrorConstants.identityIdSessionExpiredError.errorDescription,
            AuthPluginErrorConstants.identityIdSessionExpiredError.recoverySuggestion)

        let awsCredentialsError = AuthError.sessionExpired(
            AuthPluginErrorConstants.awsCredentialsSessionExpiredError.errorDescription,
            AuthPluginErrorConstants.awsCredentialsSessionExpiredError.recoverySuggestion)

        let tokensError = AuthError.sessionExpired(
            AuthPluginErrorConstants.cognitoTokensSessionExpiredError.errorDescription,
            AuthPluginErrorConstants.cognitoTokensSessionExpiredError.recoverySuggestion)

        let authSession = AWSAuthCognitoSession(isSignedIn: true,
                                                identityIdResult: .failure(identityIdError),
                                                awsCredentialsResult: .failure(awsCredentialsError),
                                                cognitoTokensResult: .failure(tokensError))
        return authSession
    }

    static func userSubErrorForIdentityPoolFederation() -> AuthError {
        let userSubError = AuthError.service(
            AuthPluginErrorConstants.userSubSignedInThroughCIDPError.errorDescription,
            AuthPluginErrorConstants.userSubSignedInThroughCIDPError.recoverySuggestion,
            AWSCognitoAuthError.invalidAccountTypeException)
        return userSubError
    }

    static func cognitoTokenErrorForIdentityPoolFederation() -> AuthError {
        let tokensError = AuthError.service(
            AuthPluginErrorConstants.cognitoTokenSignedInThroughCIDPError.errorDescription,
            AuthPluginErrorConstants.cognitoTokenSignedInThroughCIDPError.recoverySuggestion,
            AWSCognitoAuthError.invalidAccountTypeException)
        return tokensError
    }

    static func identityIdErrorForInvalidConfiguration() -> AuthError {
        let identityIdError = AuthError.service(
            AuthPluginErrorConstants.signedInIdentityIdWithNoCIDPError.errorDescription,
            AuthPluginErrorConstants.signedInIdentityIdWithNoCIDPError.recoverySuggestion,
            AWSCognitoAuthError.invalidAccountTypeException)
        return identityIdError
    }

    static func awsCredentialsErrorForInvalidConfiguration() -> AuthError {
        let awsCredentialsError = AuthError.service(
            AuthPluginErrorConstants.signedInAWSCredentialsWithNoCIDPError.errorDescription,
            AuthPluginErrorConstants.signedInAWSCredentialsWithNoCIDPError.recoverySuggestion,
            AWSCognitoAuthError.invalidAccountTypeException)
        return awsCredentialsError
    }
}
