//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import AWSMobileClient

extension AuthenticationProviderAdapter {

    func signIn(request: AuthSignInRequest,
                completionHandler: @escaping (Result<AuthSignInResult, AuthError>) -> Void) {

        // AuthSignInRequest.validate method should have already validated the username and the below line
        // is just to avoid optional unwrapping.
        let username = request.username ?? ""

        // Password can be nil, but awsmobileclient need it to have a dummy value.
        let password = request.password ?? ""

        let clientMetaData = (request.options.pluginOptions as? AWSAuthSignInOptions)?.metadata ?? [:]

        awsMobileClient.signIn(username: username,
                               password: password,
                               validationData: nil,
                               clientMetaData: clientMetaData) { [weak self] result, error in
                                guard let self = self else { return }

                                guard error == nil else {
                                    let result = self.convertSignInErrorToResult(error!)
                                    completionHandler(result)
                                    return
                                }

                                guard let result = result else {
                                    // This should not happen, return an unknown error.
                                    let error = AuthError.unknown("Could not read result from signIn operation")
                                    completionHandler(.failure(error))
                                    return
                                }

                                guard let signInNextStep = try? result.toAmplifyAuthSignInStep() else {
                                    // Could not find any next step for signIn. This should not happen.
                                    let error = AuthError.unknown("""
                                        Invalid state for signIn \(result.signInState)
                                        """)
                                    completionHandler(.failure(error))
                                    return
                                }
                                let authResult = AuthSignInResult(nextStep: signInNextStep)
                                completionHandler(.success(authResult))
        }

    }

    func signInWithWebUI(request: AuthWebUISignInRequest,
                         completionHandler: @escaping (Result<AuthSignInResult, AuthError>) -> Void) {

        let window = request.presentationAnchor
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }

            self.showSignInWebView(window: window,
                                   request: request,
                                   completionHandler: completionHandler)
        }
    }

    func confirmSignIn(request: AuthConfirmSignInRequest,
                       completionHandler: @escaping (Result<AuthSignInResult, AuthError>) -> Void) {

        let userAttributes = (request.options.pluginOptions as? AWSAuthConfirmSignInOptions)?.userAttributes ?? []
        let mobileClientUserAttributes = userAttributes.reduce(into: [String: String]()) {
            $0[$1.key.rawValue] = $1.value
        }
        let clientMetaData = (request.options.pluginOptions as? AWSAuthConfirmSignInOptions)?.metadata

        awsMobileClient.confirmSignIn(challengeResponse: request.challengeResponse,
                                      userAttributes: mobileClientUserAttributes,
                                      clientMetaData: clientMetaData ?? [:]) { [weak self] result, error in
                                        guard let self = self else { return }

                                        if let error = error {
                                            let result = self.convertSignInErrorToResult(error)
                                            completionHandler(result)
                                            return
                                        }

                                        guard let result = result else {
                                            // This should not happen, return an unknown error.
                                            let error = AuthError.unknown("""
                                            Could not read result from confirmSignIn operation
                                            """)
                                            completionHandler(.failure(error))
                                            return
                                        }

                                        guard let nextStep = try? result.toAmplifyAuthSignInStep() else {
                                            // Could not find any next step for signIn. This should not happen.
                                            let error = AuthError.unknown("""
                                                Invalid state for signIn \(result.signInState)
                                                """)
                                            completionHandler(.failure(error))
                                            return
                                        }
                                        let authResult = AuthSignInResult(nextStep: nextStep)
                                        completionHandler(.success(authResult))
        }

    }

    // MARK: - Internal methods
    private func showSignInWebView(window: UIWindow,
                                   request: AuthWebUISignInRequest,
                                   completionHandler: @escaping (Result<AuthSignInResult, AuthError>) -> Void) {

        // Stop the execution here if we are not running on the main thread.
        // There is no point on returning an error back to the developer, because
        // they do not control how the UI is presented.
        dispatchPrecondition(condition: .onQueue(DispatchQueue.main))

        let idpIdentifier = (request.options.pluginOptions as? AWSAuthWebUISignInOptions)?.idpIdentifier
        let federationProviderName = (request.options.pluginOptions as? AWSAuthWebUISignInOptions)?
            .federationProviderName
        let hostedUIOptions = HostedUIOptions(disableFederation: false,
                                              scopes: request.options.scopes,
                                              identityProvider: request.authProvider?.toCognitoHostedUIString(),
                                              idpIdentifier: idpIdentifier,
                                              federationProviderName: federationProviderName,
                                              signInURIQueryParameters: request.options.signInQueryParameters,
                                              tokenURIQueryParameters: request.options.tokenQueryParameters,
                                              signOutURIQueryParameters: request.options.signOutQueryParameters)

        // Create a navigation controller with an empty UIViewController.
        let navController = UINavigationController(rootViewController: UIViewController())
        navController.isNavigationBarHidden = true
        navController.modalPresentationStyle = .overCurrentContext

        // Get top most view controller to present a navController
        var parentViewController = window.rootViewController
        while (parentViewController?.presentedViewController) != nil {
            parentViewController = parentViewController?.presentedViewController
        }

        parentViewController?.present(navController, animated: false, completion: {

            self.awsMobileClient.showSignIn(navigationController: navController,
                                            signInUIOptions: SignInUIOptions(),
                                            hostedUIOptions: hostedUIOptions) { [weak self] state, error in

                DispatchQueue.main.async {
                    navController.dismiss(animated: false) {
                        guard let self = self else { return }

                        if let error = error {
                            let authError = self.convertSignUIErrorToAuthError(error)
                            completionHandler(.failure(authError))
                            return
                        }

                        guard let state = state, state == .signedIn else {

                            let error = AuthError.unknown("signInWithWebUI did not produce a valid result.")
                            completionHandler(.failure(error))
                            return
                        }
                        let authResult = AuthSignInResult(nextStep: .done)
                        completionHandler(.success(authResult))
                    }
                }
            }

        })
    }

    private func convertSignInErrorToResult(_ error: Error) -> Result<AuthSignInResult, AuthError> {
        if let awsMobileClientError = error as? AWSMobileClientError {
            if case .passwordResetRequired = awsMobileClientError {
                let authResult = AuthSignInResult(nextStep: .resetPassword(nil))
                return .success(authResult)
            } else if case .userNotConfirmed = awsMobileClientError {
                let authResult = AuthSignInResult(nextStep: .confirmSignUp(nil))
                return .success(authResult)
            }
        }
        let authError = AuthErrorHelper.toAuthError(error)
        return .failure(authError)
    }

    private func convertSignUIErrorToAuthError(_ error: Error) -> AuthError {
        if let awsMobileClientError = error as? AWSMobileClientError {
            switch awsMobileClientError {
            case .securityFailed(message: _):
                // This error is caused when the redirected url's query parameter `state` has a different value from
                // value it was set before.
                return AuthError.service(
                    AuthPluginErrorConstants.hostedUISecurityFailedError.errorDescription,
                    AuthPluginErrorConstants.hostedUISecurityFailedError.recoverySuggestion)
            case .badRequest(let message):
                // Received when we get back an error parameter in the redirect url
                return AuthError.service(message, AuthPluginErrorConstants.hostedUIBadRequestError)
            case .idTokenAndAcceessTokenNotIssued(let message):
                // Received when there is no tokens after the signIn is complete. This should not happen, so
                // return an unknown error.
                return AuthError.unknown(message)
            case .userCancelledSignIn(message: _):
                // User clicked cancel
                return AuthError.service(
                    AuthPluginErrorConstants.hostedUIUserCancelledError.errorDescription,
                    AuthPluginErrorConstants.hostedUIUserCancelledError.recoverySuggestion,
                    AWSCognitoAuthError.userCancelled)
            default:
                break
            }

        }
        let authError = AuthErrorHelper.toAuthError(error)
        return authError
    }

}
