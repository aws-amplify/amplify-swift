//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import AWSCore
import AWSPluginsCore
#if COCOAPODS
import AWSMobileClient
#else
import AWSMobileClientXCF
#endif

extension AuthorizationProviderAdapter {

    /// Creates session for a signedIn user.
    ///
    /// Session values available as a signedIn user depend on the way the user signedIn and the configurations enabled
    /// for the current signedIn user. Make sure that this method is called only for signedIn state and not for
    /// signedOut or un-authenticated state.
    ///
    /// The following scenarios can happen:
    /// - User is signedIn through Cognito User Pool and Identity Pool is not configured
    /// - User is signedIn through Cognito User Pool but refresh token is expired
    /// - User is signedIn through Cognito User Pool but access token couldnot be refreshed because of network or
    /// service issue
    /// - User is signedIn through Cognito User Pool but aws credentials couldnot be refreshed because of network or
    /// service issue
    /// - User is signedIn through Cognito Identity Pool
    /// - User is signedIn through Cognito Identity Pool but aws credentials couldnot be refreshed because of network or
    /// service issue
    /// - Parameter completionHandler: Completion handler to return the result.
    func fetchSignedInSession( _ completionHandler: @escaping SessionCompletionHandler) {

        // User can be signed in to user pools or federated to identityPool.
        // Call getTokens first to verify that the signedIn user is in UserPool or not.
        awsMobileClient.getTokens { [weak self] tokens, error in
            guard let self = self else {
                return
            }
            guard error == nil else {

                if let urlError = error as NSError?, urlError.domain == NSURLErrorDomain {
                    self.fetchSignedInSessionWithOfflineError(completionHandler)

                } else if let awsMobileClientError = error as? AWSMobileClientError {

                    if case .notSignedIn = awsMobileClientError {
                        self.fetchIdentityPoolSignedInSession(completionHandler)

                    } else if case .unableToSignIn = awsMobileClientError {
                        self.fetchSignedInSessionWithSessionExpiredError(completionHandler)

                    } else {
                        self.fetchSignedInSession(withError: AuthErrorHelper.toAuthError(error!),
                                                  completionHandler)
                    }
                } else if self.isErrorCausedByUserNotFound(error) {
                    self.awsMobileClient.signOutLocally()
                    self.fetchSignedOutSession(completionHandler)
                    Amplify.Hub.dispatch(to: .auth, payload: HubPayload(eventName: HubPayload.EventName.Auth.signedOut))
                } else {
                    self.fetchSignedInSession(withError: AuthErrorHelper.toAuthError(error!), completionHandler)
                }
                return
            }

            guard let tokens = tokens else {
                let error = AuthError.unknown("""
                    Could not fetch AWS Cognito tokens, but there was no error reported back from
                    AWSMobileClient.getTokens call.
                    """)
                self.fetchSignedInSession(withError: error, completionHandler)
                return
            }

            guard let userSub = tokens.idToken?.claims?["sub"] as? String else {
                let error = AuthError.unknown("""
                Could not retreive user sub from the fetched Cognito tokens. There was no error in calling
                AWSMobileClient.getTokens.
                """)
                self.retrieveAWSCredentials(withTokensResult: .success(tokens.toAWSCognitoUserPoolTokens()),
                                            userSubResult: .failure(error),
                                            completionHandler: completionHandler)
                return
            }

            self.retrieveAWSCredentials(withTokensResult: .success(tokens.toAWSCognitoUserPoolTokens()),
                                        userSubResult: .success(userSub),
                                        completionHandler: completionHandler)
        }
    }

    /// The user is signed in by federating through Cognito Identity Pool
    ///
    /// In this case we just fetch the aws credentials and identity id. There is no Cognito User Pool tokens
    /// or usersub.
    private func fetchIdentityPoolSignedInSession(_ completionHandler: @escaping SessionCompletionHandler) {
        let tokensError = AuthCognitoSignedInSessionHelper.cognitoTokenErrorForIdentityPoolFederation()
        let userSubError = AuthCognitoSignedInSessionHelper.userSubErrorForIdentityPoolFederation()
        retrieveAWSCredentials(withTokensResult: .failure(tokensError),
                               userSubResult: .failure(userSubError),
                               completionHandler: completionHandler)
    }

    /// Build the session with valid Cognito tokens.
    private func retrieveAWSCredentials(withTokensResult tokenResult: Result<AuthCognitoTokens, AuthError>,
                                        userSubResult: Result<String, AuthError>,
                                        completionHandler: @escaping SessionCompletionHandler) {

        awsMobileClient.getAWSCredentials { [weak self] awsCredentials, error in
            guard let self = self else {
                return
            }
            guard error == nil else {

                if let urlError = error as NSError?, urlError.domain == NSURLErrorDomain {
                    self.fetchSignedInSessionWithOfflineError(completionHandler)

                } else if self.isErrorCausedByMisconfiguredIdentityPool(error!) {
                    self.fetchSignedInSessionWithNoIdentityPool(withTokensResult: tokenResult,
                                                                userSubResult: userSubResult,
                                                                completionHandler)

                } else if let awsMobileClientError = error as? AWSMobileClientError,
                    case .unableToSignIn = awsMobileClientError {
                    self.fetchSignedInSessionWithSessionExpiredError(completionHandler)

                } else {
                    self.fetchSignedInSession(withError: AuthErrorHelper.toAuthError(error!), completionHandler)
                }
                return
            }

            guard let credentials = awsCredentials else {
                let error = AuthError.unknown("""
                    Could not fetch AWS Cognito credentials, but there was no error reported back from
                    AWSMobileClient.getAWSCredentials call.
                    """)
                self.fetchSignedInSession(withError: error, completionHandler)
                return
            }
            self.retrieveIdentityId(withCredentials: credentials,
                                    tokenResult: tokenResult,
                                    userSubResult: userSubResult,
                                    completionHandler: completionHandler)
        }
    }

    /// Retrieve identity Id of the signedIn user.
    ///
    /// At this point we have already fetched AWS Credentials using an identity Id. So the expectation is that there is
    /// a valid identity id cached.
    private func retrieveIdentityId(withCredentials credentials: AWSCredentials,
                                    tokenResult: Result<AuthCognitoTokens, AuthError>,
                                    userSubResult: Result<String, AuthError>,
                                    completionHandler: @escaping SessionCompletionHandler) {

        awsMobileClient.getIdentityId().continueWith { (task) -> Any? in

            if let urlError = task.error as NSError?, urlError.domain == NSURLErrorDomain {
                self.fetchSignedInSessionWithOfflineError(completionHandler)
                return nil
            }

            if let awsMobileClientError = task.error as? AWSMobileClientError,
               case .unableToSignIn = awsMobileClientError {
                self.fetchSignedInSessionWithSessionExpiredError(completionHandler)
                return nil
            }

            if let error = task.error {
                let authError = AuthErrorHelper.toAuthError(error)
                self.fetchSignedInSession(withError: authError, completionHandler)
                return nil
            }

            guard let identityId = task.result as String? else {
                let error = AuthError.unknown("""
                    Could not fetch Identity Id from Identity Pool, but there was no error reported back from
                    AWSMobileClient.getIdentityId call.
                    """)
                self.fetchSignedInSession(withError: error, completionHandler)
                return nil
            }

            do {
                let amplifyCredentials = try credentials.toAmplifyAWSCredentials()
                let authSession = AWSAuthCognitoSession(isSignedIn: true,
                                                        userSubResult: userSubResult,
                                                        identityIdResult: .success(identityId),
                                                        awsCredentialsResult: .success(amplifyCredentials),
                                                        cognitoTokensResult: tokenResult)
                completionHandler(.success(authSession))
            } catch {
                let authError = AuthErrorHelper.toAuthError(error)
                self.fetchSignedInSession(withError: authError, completionHandler)
            }
            return nil
        }
    }

    /// Session has expired, user should re-authenticate to continue.
    private func fetchSignedInSessionWithSessionExpiredError(_ completionHandler: SessionCompletionHandler) {
        let authSession = AuthCognitoSignedInSessionHelper.makeExpiredSignedInSession()
        completionHandler(.success(authSession))
    }

    /// Could not fetch the session because of network issue.
    private func fetchSignedInSessionWithOfflineError(_ completionHandler: SessionCompletionHandler) {
        let authSession = AuthCognitoSignedInSessionHelper.makeOfflineSignedInSession()
        completionHandler(.success(authSession))
    }

    /// Could not fetch the session because of an error.
    private func fetchSignedInSession(withError error: AuthError,
                                      _ completionHandler: SessionCompletionHandler) {
        let authSession = AuthCognitoSignedInSessionHelper.makeSignedInSession(withUnhandledError: error)
        completionHandler(.success(authSession))
    }

    /// Auth session with no AWS Cognito Identity Pool configured.
    ///
    /// Cognito Identity Pool is not configured for this authentication provider.
    private func fetchSignedInSessionWithNoIdentityPool(
        withTokensResult tokenResult: Result<AuthCognitoTokens, AuthError>,
        userSubResult: Result<String, AuthError>,
        _ completionHandler: SessionCompletionHandler) {

        let identityIdError = AuthCognitoSignedInSessionHelper.identityIdErrorForInvalidConfiguration()
        let credentialsError = AuthCognitoSignedInSessionHelper.awsCredentialsErrorForInvalidConfiguration()
        let authSession = AWSAuthCognitoSession(isSignedIn: true,
                                                userSubResult: userSubResult,
                                                identityIdResult: .failure(identityIdError),
                                                awsCredentialsResult: .failure(credentialsError),
                                                cognitoTokensResult: tokenResult)
        completionHandler(.success(authSession))
    }

    private func isErrorCausedByMisconfiguredIdentityPool(_ error: Error) -> Bool {
        if let awsMobileClientError = error as? AWSMobileClientError,
            case .cognitoIdentityPoolNotConfigured = awsMobileClientError {
            return true
        }
        if let cognitoIdentityPoolError = error as NSError?,
            cognitoIdentityPoolError.domain == AWSCognitoIdentityErrorDomain,
            cognitoIdentityPoolError.code == AWSCognitoIdentityErrorType.notAuthorized.rawValue {
            return true
        }
        return false
    }

    private func isErrorCausedByUserNotFound(_ error: Error?) -> Bool {
        if let cognitoIdentityProviderError = error as NSError?,
            cognitoIdentityProviderError.domain == AWSCognitoIdentityProviderErrorDomain,
            cognitoIdentityProviderError.code == AWSCognitoIdentityProviderErrorType.userNotFound.rawValue {
            return true
        }
        return false
    }
}
