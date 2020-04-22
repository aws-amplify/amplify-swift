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
                completionHandler: @escaping (Result<AuthSignInResult, AmplifyAuthError>) -> Void) {

        // AuthSignInRequest.validate method should have already validated the username and the below line
        // is just to avoid optional unwrapping.
        let username = request.username ?? ""

        // Password can be nil, but awsmobileclient need it to have a dummy value.
        let password = request.password ?? ""

        // AWSMobileClient internally uses the validationData as the clientMetaData, so passing the metaData
        // to the validationData here.
        let validationData = (request.options.pluginOptions as? AWSAuthSignInOptions)?.metadata
        awsMobileClient.signIn(username: username,
                               password: password,
                               validationData: validationData) { result, error in

                                guard error == nil else {
                                    let authError = AuthErrorHelper.toAmplifyAuthError(error!)
                                    completionHandler(.failure(authError))
                                    return
                                }

                                guard let result = result else {
                                    // This should not happen, return an unknown error.
                                    let error = AmplifyAuthError.unknown("Could not read result from signIn operation")
                                    completionHandler(.failure(error))
                                    return
                                }

                                guard result.signInState != .signedIn else {
                                    // Return if the user has signedIn, this is a terminal step of signIn.
                                    let authResult = AuthSignInResult(nextStep: .done)
                                    completionHandler(.success(authResult))
                                    return
                                }

                                guard let nextStep = try? result.signInState.toAmplifyAuthSignInStep() else {
                                    let error = AmplifyAuthError.unknown("Invalid state for signIn \(result.signInState)")
                                    completionHandler(.failure(error))
                                    return
                                }

                                let authResult = AuthSignInResult(nextStep: nextStep)
                                completionHandler(.success(authResult))
        }

    }
}
