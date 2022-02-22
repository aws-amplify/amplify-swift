//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
#if COCOAPODS
import AWSMobileClient
#else
import AWSMobileClientXCF
#endif

typealias SigInResultCompletion = (Result<AuthSignInResult, AuthError>) -> Void

extension AuthenticationProviderAdapter {

    func signIn(request: AuthSignInRequest,
                completionHandler: @escaping SigInResultCompletion) {

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
                let error = AuthError.unknown("Invalid state for signIn \(result.signInState)")
                completionHandler(.failure(error))
                return
            }
            self.userdefaults.storePreferredBrowserSession(privateSessionPrefered: false)
            let authResult = AuthSignInResult(nextStep: signInNextStep)
            completionHandler(.success(authResult))
        }

    }

    func signInWithWebUI(request: AuthWebUISignInRequest,
                         completionHandler: @escaping SigInResultCompletion) {

        let presentationAnchor = request.presentationAnchor
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }

            self.showSignInWebView(presentationAnchor: presentationAnchor,
                                   request: request,
                                   completionHandler: completionHandler)
        }
    }

    func confirmSignIn(request: AuthConfirmSignInRequest,
                       completionHandler: @escaping SigInResultCompletion) {

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
                let error = AuthError.unknown("Could not read result from confirmSignIn operation")
                completionHandler(.failure(error))
                return
            }

            guard let nextStep = try? result.toAmplifyAuthSignInStep() else {
                // Could not find any next step for signIn. This should not happen.
                let error = AuthError.unknown("Invalid state for signIn \(result.signInState)")
                completionHandler(.failure(error))
                return
            }
            let authResult = AuthSignInResult(nextStep: nextStep)
            completionHandler(.success(authResult))
        }

    }

    // MARK: - Internal methods
    private func showSignInWebView(presentationAnchor: AuthUIPresentationAnchor,
                                   request: AuthWebUISignInRequest,
                                   completionHandler: @escaping SigInResultCompletion) {

        // Stop the execution here if we are not running on the main thread.
        // There is no point on returning an error back to the developer, because
        // they do not control how the UI is presented.
        dispatchPrecondition(condition: .onQueue(DispatchQueue.main))

        let pluginOptions = request.options.pluginOptions as? AWSAuthWebUISignInOptions
        let idpIdentifier = pluginOptions?.idpIdentifier
        let federationProviderName = pluginOptions?.federationProviderName
        let preferPrivateSession = pluginOptions?.preferPrivateSession ?? false
        let hostedUIOptions = HostedUIOptions(disableFederation: false,
                                              scopes: request.options.scopes,
                                              identityProvider: request.authProvider?.toCognitoHostedUIString(),
                                              idpIdentifier: idpIdentifier,
                                              federationProviderName: federationProviderName,
                                              signInURIQueryParameters: request.options.signInQueryParameters,
                                              tokenURIQueryParameters: request.options.tokenQueryParameters,
                                              signOutURIQueryParameters: request.options.signOutQueryParameters,
                                              signInPrivateSession: preferPrivateSession)

        if #available(iOS 13, *) {
            launchASWebAuthenticationSession(presentationAnchor: presentationAnchor,
                                             hostedUIOptions: hostedUIOptions,
                                             preferPrivateSession: preferPrivateSession,
                                             completionHandler: completionHandler)
        } else {
            launchSFAuthenticationSession(presentationAnchor: presentationAnchor,
                                          hostedUIOptions: hostedUIOptions,
                                          completionHandler: completionHandler)
        }

    }

    private func launchSFAuthenticationSession(presentationAnchor: AuthUIPresentationAnchor,
                                               hostedUIOptions: HostedUIOptions,
                                               completionHandler: @escaping SigInResultCompletion) {
        let navController = ModalPresentingNavigationController(rootViewController: UIViewController())
        navController.isNavigationBarHidden = true
        navController.modalPresentationStyle = .overCurrentContext

        // Get top most view controller to present a navController
        var parentViewController = presentationAnchor.rootViewController
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
                        self.handleHostedUIResult(state: state, error: error, completionHandler: completionHandler)
                    }
                }
            }
        })
    }

    @available(iOS 13, *)
    private func launchASWebAuthenticationSession(presentationAnchor: AuthUIPresentationAnchor,
                                                  hostedUIOptions: HostedUIOptions,
                                                  preferPrivateSession: Bool,
                                                  completionHandler: @escaping SigInResultCompletion) {
        awsMobileClient.showSignIn(uiwindow: presentationAnchor,
                                   hostedUIOptions: hostedUIOptions) { [weak self] state, error in
            guard let self = self else { return }
            self.handleHostedUIResult(state: state,
                                      error: error,
                                      preferPrivateSession: preferPrivateSession,
                                      completionHandler: completionHandler)
        }
    }

    private func handleHostedUIResult(state: UserState?,
                                      error: Error?,
                                      preferPrivateSession: Bool = false,
                                      completionHandler: @escaping SigInResultCompletion) {
        if let error = error {
            let authError = convertSignInUIErrorToAuthError(error)
            completionHandler(.failure(authError))
            return
        }

        guard let signedInState = state, signedInState == .signedIn else {

            let error = AuthError.unknown("signInWithWebUI did not produce a valid result \(state?.rawValue ?? "").")
            completionHandler(.failure(error))
            return
        }
        userdefaults.storePreferredBrowserSession(privateSessionPrefered: preferPrivateSession)
        let authResult = AuthSignInResult(nextStep: .done)
        completionHandler(.success(authResult))
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

    private func convertSignInUIErrorToAuthError(_ error: Error) -> AuthError {
        if AuthErrorHelper.didUserCancelHostedUI(error) {
            return AuthError.service(
                AuthPluginErrorConstants.hostedUIUserCancelledError.errorDescription,
                AuthPluginErrorConstants.hostedUIUserCancelledError.recoverySuggestion,
                AWSCognitoAuthError.userCancelled)
        }
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
        if self.isErrorCausedByBadRequest(error) {
            let errorDescription = error._userInfo?["error"]?
                .description.trimmingCharacters(in: .whitespaces) ?? "unknown error"
            return AuthError.service(errorDescription,
                                     AuthPluginErrorConstants.hostedUIBadRequestError,
                                     error)
        }
        let authError = AuthErrorHelper.toAuthError(error)
        return authError
    }
    
    private func isErrorCausedByBadRequest(_ error: Error?) -> Bool {
        if let cognitoAuthError = error as NSError?,
               cognitoAuthError.domain == AWSCognitoAuthErrorDomain,
               cognitoAuthError.code == AWSCognitoAuthClientErrorType.errorBadRequest.rawValue {
            return true
        }
        return false
    }

    private class ModalPresentingNavigationController: UINavigationController {

        override func present(_ viewControllerToPresent: UIViewController,
                              animated flag: Bool,
                              completion: (() -> Void)? = nil) {
            if #available(iOS 13, *) {
                viewControllerToPresent.isModalInPresentation = true
            }
            super.present(viewControllerToPresent, animated: flag, completion: completion)
        }
    }

}
