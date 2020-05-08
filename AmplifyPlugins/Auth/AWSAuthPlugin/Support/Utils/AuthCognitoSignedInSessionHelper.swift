//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify

struct AuthCognitoSignedInSessionHelper {

    static func makeOfflineSignedInSession() -> AWSAuthCognitoSession {
        let identityIdError = AmplifyAuthError.service(
            AuthPluginErrorConstants.identityIdOfflineError.errorDescription,
            AuthPluginErrorConstants.identityIdOfflineError.recoverySuggestion,
            AWSCognitoAuthError.network)

        let awsCredentialsError = AmplifyAuthError.service(
            AuthPluginErrorConstants.awsCredentialsOfflineError.errorDescription,
            AuthPluginErrorConstants.awsCredentialsOfflineError.recoverySuggestion,
            AWSCognitoAuthError.network)

        let tokensError = AmplifyAuthError.service(
            AuthPluginErrorConstants.cognitoTokenOfflineError.errorDescription,
            AuthPluginErrorConstants.cognitoTokenOfflineError.recoverySuggestion,
            AWSCognitoAuthError.network)
        let userSubError = AmplifyAuthError.service(
            AuthPluginErrorConstants.usersubOfflineError.errorDescription,
            AuthPluginErrorConstants.usersubOfflineError.recoverySuggestion,
            AWSCognitoAuthError.network)

        let authSession = AWSAuthCognitoSession(isSignedIn: true,
                                                userSubResult: .failure(userSubError),
                                                identityIdResult: .failure(identityIdError),
                                                awsCredentialsResult: .failure(awsCredentialsError),
                                                cognitoTokensResult: .failure(tokensError))
        return authSession
    }

    static func makeExpiredSignedInSession() -> AWSAuthCognitoSession {
        let identityIdError = AmplifyAuthError.service(
            AuthPluginErrorConstants.identityIdSessionExpiredError.errorDescription,
            AuthPluginErrorConstants.identityIdSessionExpiredError.recoverySuggestion,
            AWSCognitoAuthError.sessionExpired)

        let awsCredentialsError = AmplifyAuthError.service(
            AuthPluginErrorConstants.awsCredentialsSessionExpiredError.errorDescription,
            AuthPluginErrorConstants.awsCredentialsSessionExpiredError.recoverySuggestion,
            AWSCognitoAuthError.sessionExpired)

        let tokensError = AmplifyAuthError.service(
            AuthPluginErrorConstants.cognitoTokensSessionExpiredError.errorDescription,
            AuthPluginErrorConstants.cognitoTokensSessionExpiredError.recoverySuggestion,
            AWSCognitoAuthError.sessionExpired)

        let userSubError = AmplifyAuthError.service(
            AuthPluginErrorConstants.usersubSessionExpiredError.errorDescription,
            AuthPluginErrorConstants.usersubSessionExpiredError.recoverySuggestion,
            AWSCognitoAuthError.sessionExpired)

        let authSession = AWSAuthCognitoSession(isSignedIn: true,
                                                userSubResult: .failure(userSubError),
                                                identityIdResult: .failure(identityIdError),
                                                awsCredentialsResult: .failure(awsCredentialsError),
                                                cognitoTokensResult: .failure(tokensError))
        return authSession
    }

    /// SignedIn session with any unhandled error
    ///
    /// - Parameter error: Unhandled error
    /// - Returns: Session will have isSignedIn = false
    static func makeSignedInSession(withUnhandledError error: AmplifyAuthError) -> AWSAuthCognitoSession {

        let authSession = AWSAuthCognitoSession(isSignedIn: true,
                                                userSubResult: .failure(error),
                                                identityIdResult: .failure(error),
                                                awsCredentialsResult: .failure(error),
                                                cognitoTokensResult: .failure(error))
        return authSession
    }

    static func userSubErrorForIdentityPoolFederation() -> AmplifyAuthError {
        let userSubError = AmplifyAuthError.service(
            AuthPluginErrorConstants.userSubSignedInThroughCIDPError.errorDescription,
            AuthPluginErrorConstants.userSubSignedInThroughCIDPError.recoverySuggestion,
            AWSCognitoAuthError.invalidAccountTypeException)
        return userSubError
    }

    static func cognitoTokenErrorForIdentityPoolFederation() -> AmplifyAuthError {
        let tokensError = AmplifyAuthError.service(
            AuthPluginErrorConstants.cognitoTokenSignedInThroughCIDPError.errorDescription,
            AuthPluginErrorConstants.cognitoTokenSignedInThroughCIDPError.recoverySuggestion,
            AWSCognitoAuthError.invalidAccountTypeException)
        return tokensError
    }

    static func identityIdErrorForInvalidConfiguration() -> AmplifyAuthError {
        let identityIdError = AmplifyAuthError.service(
            AuthPluginErrorConstants.signedInIdentityIdWithNoCIDPError.errorDescription,
            AuthPluginErrorConstants.signedInIdentityIdWithNoCIDPError.recoverySuggestion,
            AWSCognitoAuthError.invalidAccountTypeException)
        return identityIdError
    }

    static func awsCredentialsErrorForInvalidConfiguration() -> AmplifyAuthError {
        let awsCredentialsError = AmplifyAuthError.service(
            AuthPluginErrorConstants.signedInAWSCredentialsWithNoCIDPError.errorDescription,
            AuthPluginErrorConstants.signedInAWSCredentialsWithNoCIDPError.recoverySuggestion,
            AWSCognitoAuthError.invalidAccountTypeException)
        return awsCredentialsError
    }
}
